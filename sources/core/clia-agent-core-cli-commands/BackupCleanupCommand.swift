import ArgumentParser
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct BackupCleanupCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "cleanup-backups",
      abstract: "Plan/archive cleanup of *.bak triad backups under .clia/agents"
    )
  }

  public init() {}

  @Option(name: .customLong("slug"), help: "Limit to a single agent slug")
  public var slug: String?

  @Option(name: .customLong("path"), help: "Root path (default: CWD)")
  public var path: String?

  @Option(
    name: .customLong("archive-dir"),
    help:
      "Destination directory for archived backups (default: .wrkstrm/backups/agents-archive/<stamp>)"
  )
  public var archiveDir: String?

  @Flag(name: .customLong("apply"), help: "Apply actions (move backups to archive)")
  public var apply: Bool = false

  @Flag(name: .customLong("list"), help: "List backups and status (no writes)")
  public var list: Bool = false

  @Flag(name: .customLong("all"), help: "Scan all agent directories under --path")
  public var all: Bool = false

  @Flag(name: .customLong("rank"), help: "Summarize safe-to-archive bytes per agent (descending)")
  public var rank: Bool = false

  @Flag(name: .customLong("json"), help: "Emit JSON for --list/--rank output")
  public var json: Bool = false

  @Option(name: .customLong("top"), help: "Limit rank output to top N agents (default: all)")
  public var top: Int = 0

  public func run() throws {
    let fm = FileManager.default
    let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
    if apply {
      try ToolUsePolicy.guardAllowed(.cleanupBackupsApply, under: root)
    }
    let targets = try collectAgentDirs(under: root)
    var backups: [(bak: URL, cur: URL?)] = []
    for dir in targets {
      let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
      for f in files where f.lastPathComponent.hasSuffix(".bak") {
        let orig = f.deletingPathExtension()  // removes .bak
        let exists = fm.fileExists(atPath: orig.path)
        backups.append((bak: f, cur: exists ? orig : nil))
      }
    }

    if backups.isEmpty {
      print("[cleanup-backups] no .bak files found under agents directories")
      return
    }

    let stamp = isoStamp().replacingOccurrences(of: ":", with: "-")
    let archiveRoot = URL(fileURLWithPath: archiveDir ?? ".wrkstrm/backups/agents-archive/\(stamp)")
    var manifest: [[String: Any]] = []
    var totalsBytesByAgent: [String: Int] = [:]
    var totalsCountByAgent: [String: Int] = [:]
    var safeCount = 0
    var keepCount = 0
    for item in backups.sorted(by: { $0.bak.path < $1.bak.path }) {
      let kind = docKind(for: item.bak)
      let agent = extractAgentSlug(from: item.bak)
      let cur = item.cur
      let status: String
      var reason = ""
      let safe: Bool = {
        if let cur, let a = canonical(cur, kind: kind), let b = canonical(item.bak, kind: kind) {
          return a == b
        }
        return false
      }()
      if cur != nil {
        if safe {
          status = apply ? "archived" : "would-archive"
          safeCount += 1
          if apply {
            try archive(file: item.bak, under: archiveRoot)
          }
        } else {
          status = "keep"
          reason = "content-differs"
          keepCount += 1
        }
      } else {
        status = "keep"
        reason = "no-current"
        keepCount += 1
      }
      var entry: [String: Any] = [
        "backup": rel(item.bak, root: root),
        "current": cur.map { rel($0, root: root) } as Any,
        "status": status,
      ]
      if !reason.isEmpty { entry["reason"] = reason }
      let bytes = (try? Data(contentsOf: item.bak)).map({ $0.count })
      if let bytes { entry["bytes"] = bytes }
      if let agent { entry["agent"] = agent }
      manifest.append(entry)
      if safe, let agent, let bytes {  // accumulate totals for ranking
        totalsBytesByAgent[agent, default: 0] += bytes
        totalsCountByAgent[agent, default: 0] += 1
      }
      if list {
        let semeq: String = {
          if let cur, let a = canonical(cur, kind: kind), let b = canonical(item.bak, kind: kind) {
            return a == b ? "yes" : "no"
          }
          return "n/a"
        }()
        if json {
          var record: [String: Any] = [
            "backup": item.bak.path,
            "current": cur?.path as Any,
            "semanticsEqual": safe,
            "bytes": bytes ?? 0,
          ]
          if let agent { record["agent"] = agent }
          if let data = try? JSONSerialization.data(
            withJSONObject: record, options: JSON.Formatting.humanOptions),
            let s = String(data: data, encoding: .utf8)
          {
            print(s)
          }
        } else {
          let bytesStr = bytes.map { "\($0) bytes" } ?? "?"
          print(
            "- backup: \(item.bak.path) | current: \(cur?.path ?? "(missing)") | semeq: \(semeq) | size: \(bytesStr)"
          )
        }
      } else {
        print("[cleanup-backups] \(status): \(item.bak.path)\(cur.map { " ← \($0.path)" } ?? "")")
      }
    }

    if rank {
      // Print ranking by total bytes desc
      let sorted = totalsBytesByAgent.sorted { $0.value > $1.value }
      let limited: [(key: String, value: Int)] = {
        guard top > 0 else { return sorted }
        return Array(sorted.prefix(top))
      }()
      if json {
        var arr: [[String: Any]] = []
        for (agent, bytes) in limited {
          arr.append(["agent": agent, "bytes": bytes, "files": totalsCountByAgent[agent] ?? 0])
        }
        if let data = try? JSONSerialization.data(
          withJSONObject: arr, options: JSON.Formatting.humanOptions)
        {
          if let s = String(data: data, encoding: .utf8) { print(s) }
        }
      } else {
        for (agent, bytes) in limited {
          let count = totalsCountByAgent[agent] ?? 0
          print("\(agent): \(bytes) bytes across \(count) file(s)")
        }
      }
    } else if apply {
      try fm.createDirectory(at: archiveRoot, withIntermediateDirectories: true)
      let mf = archiveRoot.appendingPathComponent("manifest.json")
      if (try? JSON.FileWriter.writeJSONObject(
        manifest, to: mf, options: JSON.Formatting.humanOptions)) != nil
      {
      }
      print("[cleanup-backups] archived=\(safeCount) keep=\(keepCount) dir=\(archiveRoot.path)")
    } else if !list {
      print("[cleanup-backups] plan complete — would-archive=\(safeCount) keep=\(keepCount)")
    }
  }

  // MARK: - Helpers

  private func collectAgentDirs(under root: URL) throws -> [URL] {
    let fm = FileManager.default
    var out: [URL] = []
    if let slug {
      let dir = root.appendingPathComponent(".clia/agents/\(slug)")
      if fm.fileExists(atPath: dir.path) { out.append(dir) }
      return out
    }
    guard all else {
      throw ValidationError("Specify --slug <agent> or --all to select targets")
    }
    let e = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey])
    while let url = e?.nextObject() as? URL {
      if url.lastPathComponent == "agents", url.path.contains("/.clia/") {
        if let children = try? fm.contentsOfDirectory(
          at: url, includingPropertiesForKeys: [.isDirectoryKey])
        {
          for c in children {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: c.path, isDirectory: &isDir), isDir.boolValue { out.append(c) }
          }
        }
      }
    }
    return out
  }

  private enum Kind { case agent, agenda, agency }
  private func docKind(for url: URL) -> Kind {
    let n = url.deletingPathExtension().lastPathComponent
    if n.contains(".agent.") { return .agent }
    if n.contains(".agenda.") { return .agenda }
    return .agency
  }

  private func extractAgentSlug(from url: URL) -> String? {
    let comps = url.pathComponents
    if let idx = comps.firstIndex(of: "agents"), idx + 1 < comps.count {
      return comps[idx + 1]
    }
    return nil
  }

  /// Produce canonical encoded bytes of the decoded doc after normalization, for equality checks.
  private func canonical(_ url: URL, kind: Kind) -> Data? {
    guard let raw = try? Data(contentsOf: url) else { return nil }
    let dec = JSONDecoder()
    let enc = JSONEncoder()
    enc.outputFormatting = [.sortedKeys]
    switch kind {
    case .agent:
      if let v = try? dec.decode(AgentDoc.self, from: raw) { return try? enc.encode(v) }
      if var obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any] {
        normalize(&obj)
        if let data = try? JSONSerialization.data(withJSONObject: obj),
          let v = try? dec.decode(AgentDoc.self, from: data)
        {
          return try? enc.encode(v)
        }
      }
    case .agenda:
      if let v = try? dec.decode(AgendaDoc.self, from: raw) { return try? enc.encode(v) }
      if var obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any] {
        normalize(&obj)
        if let data = try? JSONSerialization.data(withJSONObject: obj),
          let v = try? dec.decode(AgendaDoc.self, from: data)
        {
          return try? enc.encode(v)
        }
      }
    case .agency:
      if let v = try? dec.decode(AgencyDoc.self, from: raw) { return try? enc.encode(v) }
      if var obj = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any] {
        normalize(&obj)
        if let data = try? JSONSerialization.data(withJSONObject: obj),
          let v = try? dec.decode(AgencyDoc.self, from: data)
        {
          return try? enc.encode(v)
        }
      }
    }
    return nil
  }

  private func archive(file: URL, under root: URL) throws {
    let fm = FileManager.default
    let relPath = file.path
      .replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
      .replacingOccurrences(of: "..", with: "_")
    let dest = root.appendingPathComponent(relPath)
    try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? fm.removeItem(at: dest)
    try fm.moveItem(at: file, to: dest)
  }

  private func rel(_ url: URL, root: URL) -> String {
    url.path.replacingOccurrences(of: root.path + "/", with: "")
  }

  private func isoStamp() -> String { ISO8601DateFormatter().string(from: Date()) }

  // Normalization adapted from NormalizeSchemaCommand
  private func normalize(_ doc: inout [String: Any]) {
    // schemaVersion: enforce current version
    doc["schemaVersion"] = TriadSchemaVersion.current
    // Hoist sourcePath from extensions
    if var ext = doc["extensions"] as? [String: Any] {
      let extX = ext["x-source-path"] as? String
      let extSrc = ext["sourcePath"] as? String
      let top = doc["sourcePath"] as? String
      let chosen = top ?? extSrc ?? extX
      if let chosen {
        doc["sourcePath"] = chosen
        ext.removeValue(forKey: "x-source-path")
        ext.removeValue(forKey: "sourcePath")
        doc["extensions"] = ext.isEmpty ? nil : ext
      }
    }
    if let notes = doc["notes"] as? [String: Any] {
      var obj = notes
      if let inner = notes["object"] as? [String: Any] { obj = inner }
      if let blocks = obj["blocks"] as? [Any] {
        var newBlocks: [[String: Any]] = []
        for v in blocks {
          if let s = v as? String {
            newBlocks.append(["kind": "paragraph", "text": [s]])
          } else if let b = v as? [String: Any] {
            newBlocks.append(b)
          }
        }
        obj["blocks"] = newBlocks
      }
      doc["notes"] = obj
    }
    // Promote flat strings to typed sections/checklists when present
    if let arr = doc["sections"] as? [Any], arr.first is String {
      let strings = arr.compactMap { $0 as? String }
      doc["sections"] = sectionsFromFlat(strings)
    }
    if let arr = doc["checklists"] as? [Any], arr.first is String {
      let strings = arr.compactMap { $0 as? String }
      let items = strings.map { ["text": $0, "level": "required"] as [String: Any] }
      doc["checklists"] = [["items": items]]
    }
    let role = (doc["role"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if role.isEmpty, let slug = doc["slug"] as? String, !slug.isEmpty { doc["role"] = slug }
  }
  private func sectionsFromFlat(_ arr: [String]) -> [[String: Any]] {
    var titled: [String: [String]] = [:]
    var untitled: [String] = []
    for s in arr {
      if let r = s.range(of: ": ") {
        let t = String(s[..<r.lowerBound])
        let item = String(s[r.upperBound...])
        titled[t, default: []].append(item)
      } else {
        untitled.append(s)
      }
    }
    var out: [[String: Any]] = titled.map { ["title": $0.key, "items": $0.value] }
    if !untitled.isEmpty { out.append(["items": untitled]) }
    return out
  }
}
