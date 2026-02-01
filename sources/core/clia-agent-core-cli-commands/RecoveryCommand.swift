import ArgumentParser
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct RecoveryCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "recovery",
      abstract: "Recovery mode utilities: plan or restore triads from .bak backups"
    )
  }

  public init() {}

  public enum Kind: String, ExpressibleByArgument, CaseIterable {
    case agency
    case agent
    case agenda
    case all
  }

  @Option(name: .customLong("slug"), help: "Target a single agent slug; use --all to scan all")
  public var slug: String?

  @Flag(name: .customLong("all"), help: "Scan all agents under --path")
  public var all: Bool = false

  @Option(name: .customLong("path"), help: "Root path (default: CWD)")
  public var path: String?

  @Option(
    name: .customLong("kind"),
    help: "Triad kind to operate on: \(Kind.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var kind: Kind = .agency

  @Flag(
    name: .customLong("restore"),
    help: "Apply restore: copy *.json.bak over current *.json (with .pre-restore.bak safety copy)")
  public var restore: Bool = false

  @Flag(
    name: .customLong("verify"),
    help: "After restore/plan, verify typed semantic equality of restored/current vs backup")
  public var verify: Bool = false

  @Flag(name: .customLong("json"), help: "Emit JSON output for automation")
  public var json: Bool = false

  @Flag(
    name: .customLong("freeze"),
    help: "Create a repo-level recovery lock to signal other tools to avoid writes")
  public var freeze: Bool = false

  @Flag(name: .customLong("unfreeze"), help: "Remove the repo-level recovery lock")
  public var unfreeze: Bool = false

  public func run() throws {
    let fm = FileManager.default
    let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)

    // Freeze/unfreeze sentinels first if requested
    if freeze || unfreeze {
      let incidentsLock = root.appendingPathComponent(".clia/incidents/recovery.lock")
      if freeze {
        try fm.createDirectory(
          at: incidentsLock.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "locked".data(using: .utf8)?.write(to: incidentsLock)
        print("[recovery] freeze: created \(incidentsLock.path)")
      }
      if unfreeze {
        if fm.fileExists(atPath: incidentsLock.path) {
          try fm.removeItem(at: incidentsLock)
          print("[recovery] unfreeze: removed \(incidentsLock.path)")
        } else {
          print("[recovery] unfreeze: no lock present at \(incidentsLock.path)")
        }
      }
    }

    // Collect targets
    let agentDirs = try collectAgentDirs(under: root)
    var rows: [[String: Any]] = []
    var wouldRestore = 0
    var restored = 0
    let selectedKinds = kindsToCheck()
    for dir in agentDirs.sorted(by: { $0.path < $1.path }) {
      let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
      for f in files where isSelectedTriad(f, selectedKinds) {
        let bak = f.appendingPathExtension("bak")
        guard fm.fileExists(atPath: bak.path) else { continue }
        let k = docKind(for: f)
        let agent = extractAgentSlug(from: f) ?? "(unknown)"
        let semeq: Bool = {
          if let a = canonical(f, kind: k), let b = canonical(bak, kind: k) { return a == b }
          return false
        }()

        if restore {
          try ToolUsePolicy.guardAllowed(.recoveryRestore, under: root)
        }
        var status = restore ? "restored" : "would-restore"
        if semeq { status = restore ? "skipped (equal)" : "skip (equal)" }
        if restore && !semeq {
          // Make safety copy, then restore
          let pre = f.deletingPathExtension().appendingPathExtension("pre-restore.bak")
          try? fm.removeItem(at: pre)
          if let data = try? Data(contentsOf: f) { try data.write(to: pre) }
          try fm.removeItem(at: f)
          try fm.copyItem(at: bak, to: f)
          restored += 1
        } else if !restore && !semeq {
          wouldRestore += 1
        }

        var row: [String: Any] = [
          "agent": agent,
          "path": rel(f, root: root),
          "backup": rel(bak, root: root),
          "kind": String(describing: k),
          "status": status,
          "semanticsEqual": semeq,
        ]
        if verify {
          let ok: Bool = {
            if let a = canonical(f, kind: k), let b = canonical(bak, kind: k) { return a == b }
            return false
          }()
          row["postVerifyEqual"] = ok
        }
        rows.append(row)
      }
    }

    if json {
      let data = try JSONSerialization.data(
        withJSONObject: rows, options: JSON.Formatting.humanOptions)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    } else {
      for r in rows {
        let agent = r["agent"] as? String ?? "(unknown)"
        let path = r["path"] as? String ?? "?"
        let status = r["status"] as? String ?? "?"
        let semeq = (r["semanticsEqual"] as? Bool) == true ? "yes" : "no"
        print("[recovery] \(status): \(agent) — \(path) (semanticsEqual=\(semeq))")
      }
      if restore {
        print(
          "[recovery] restore complete: restored=\(restored) skippedEqual=\(rows.filter { ($0["status"] as? String)?.contains("skip") == true }.count)"
        )
      } else {
        print(
          "[recovery] plan: would-restore=\(wouldRestore) skipEqual=\(rows.count - wouldRestore)")
      }
    }
  }

  // MARK: - Helpers

  private func kindsToCheck() -> [Kind] {
    switch kind {
    case .all: return [.agent, .agenda, .agency]
    default: return [kind]
    }
  }

  private func collectAgentDirs(under root: URL) throws -> [URL] {
    let fm = FileManager.default
    var out: [URL] = []
    if let slug {
      let dir = root.appendingPathComponent(".clia/agents/\(slug)")
      if fm.fileExists(atPath: dir.path) { out.append(dir) }
      return out
    }
    guard all else { throw ValidationError("Specify --slug <agent> or --all to select targets") }
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

  private enum DocKind { case agent, agenda, agency }
  private func docKind(for url: URL) -> DocKind {
    let name = url.lastPathComponent
    if name.contains(".agent.") { return .agent }
    if name.contains(".agenda.") { return .agenda }
    return .agency
  }
  private func isSelectedTriad(_ url: URL, _ kinds: [Kind]) -> Bool {
    let k = docKind(for: url)
    let want = kinds.contains { want in
      switch (want, k) {
      case (.agent, .agent), (.agenda, .agenda), (.agency, .agency): return true
      case (.all, _): return true
      default: return false
      }
    }
    return want && url.path.hasSuffix(".json")
      && (url.path.contains(".agent.") || url.path.contains(".agenda.")
        || url.path.contains(".agency."))
  }

  private func extractAgentSlug(from url: URL) -> String? {
    let comps = url.pathComponents
    if let idx = comps.firstIndex(of: "agents"), idx + 1 < comps.count { return comps[idx + 1] }
    return nil
  }

  private func canonical(_ url: URL, kind: DocKind) -> Data? {
    guard let raw = try? Data(contentsOf: url) else { return nil }
    let dec = JSONDecoder()
    let enc = JSONEncoder()
    enc.outputFormatting = [.sortedKeys]
    switch kind {
    case .agent:
      if let v = try? dec.decode(AgentDoc.self, from: raw) { return try? enc.encode(v) }
    case .agenda:
      if let v = try? dec.decode(AgendaDoc.self, from: raw) { return try? enc.encode(v) }
    case .agency:
      if let v = try? dec.decode(AgencyDoc.self, from: raw) { return try? enc.encode(v) }
    }
    return nil
  }

  private func rel(_ url: URL, root: URL) -> String {
    url.path.replacingOccurrences(of: root.path + "/", with: "")
  }
}
