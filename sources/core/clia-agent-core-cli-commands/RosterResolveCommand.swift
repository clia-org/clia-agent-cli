import ArgumentParser
import CLIACore
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct RosterResolveCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "roster-resolve",
      abstract: "Resolve agents by All‑Contributors type, emoji, or query")
  }

  @Option(
    name: .customLong("type"), help: "All‑Contributors type (e.g., projectManagement, doc, tool)")
  public var type: String?

  @Option(name: .customLong("emoji"), help: "Emoji (e.g., 📆, 📖, 🔧)")
  public var emoji: String?

  @Option(name: .customLong("query"), help: "Freeform synonym (e.g., 'project manager', 'pjm')")
  public var query: String?

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  @Flag(name: .customLong("json"), help: "Emit JSON output")
  public var json: Bool = false

  public init() {}

  public func run() throws {
    let root =
      path.map { URL(fileURLWithPath: $0) }
      ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let specEntries = try AllContributorsSpecLoader.loadSpec(root: root)
    let mapping: [String: (emoji: String, synonyms: [String])] = specEntries.mapValues {
      ($0.emoji, $0.synonyms ?? [])
    }
    guard let key = resolveKey(spec: mapping, type: type, emoji: emoji, query: query) else {
      throw ValidationError("No matching type/emoji/query; provide --type/--emoji/--query")
    }
    let candidates = findAgentSlugs(under: root)
    var results: [[String: String]] = []
    for slug in candidates.sorted() {
      let merged = Merger.mergeAgent(slug: slug, under: root)
      if merged.slug == "unknown" { continue }
      let rawTypes = ContributionMixSupport.contributionTypes(from: merged.contributionMix)
      let (normTypes, _) = canonicalizeTypes(rawTypes, with: mapping)
      let derived = derivedEmojis(from: normTypes, with: mapping)
      let emojis = Set(merged.emojiTags).union(derived)
      if normTypes.contains(key.lowercased()) || emojis.contains(mapping[key]?.emoji ?? "") {
        let row: [String: String] = [
          "slug": merged.slug,
          "title": merged.title,
          "purpose": merged.purpose ?? merged.title,
          "path": ".clia/agents/\(slug)/",
        ]
        results.append(row)
      }
    }
    if json {
      let data = try JSONSerialization.data(
        withJSONObject: results, options: JSON.Formatting.humanOptions)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    } else {
      if results.isEmpty {
        print("No agents matched for key=\(key)")
      } else {
        for r in results { print("| \(r["slug"]!) | \(r["purpose"]!) | \(r["path"]!) |") }
      }
    }
  }

  private func resolveKey(
    spec: [String: (emoji: String, synonyms: [String])], type: String?, emoji: String?,
    query: String?
  ) -> String? {
    if let t = type?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
      // case-insensitive key match
      if let hit = spec.keys.first(where: { $0.lowercased() == t.lowercased() }) { return hit }
    }
    if let e = emoji, let hit = spec.first(where: { $0.value.emoji == e })?.key { return hit }
    if let q = query?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
      let norm = q.replacingOccurrences(of: " ", with: "-")
      for (k, v) in spec {
        if k.lowercased() == q || k.lowercased() == norm { return k }
        if v.synonyms.map({ $0.lowercased() }).contains(q) { return k }
      }
    }
    return nil
  }

  private func canonicalizeTypes(
    _ types: Set<String>, with spec: [String: (emoji: String, synonyms: [String])]
  ) -> (recognized: Set<String>, unknown: Set<String>) {
    var recognized = Set<String>()
    var unknown = Set<String>()
    let synToKey: [String: String] = spec.reduce(into: [:]) { acc, kv in
      acc[kv.key.lowercased()] = kv.key
      for s in kv.value.synonyms { acc[s.lowercased()] = kv.key }
    }
    for raw in types {
      let key = raw.lowercased()
      if let canon = synToKey[key] {
        recognized.insert(canon)
      } else {
        unknown.insert(raw)
      }
    }
    return (recognized, unknown)
  }

  private func derivedEmojis(
    from types: Set<String>, with spec: [String: (emoji: String, synonyms: [String])]
  ) -> Set<String> {
    var out = Set<String>()
    for t in types {
      if let e = spec[t]?.emoji { out.insert(e) }
    }
    return out
  }

  private func findAgentSlugs(under root: URL) -> Set<String> {
    var slugs = Set<String>()
    let fm = FileManager.default
    func collect(in dir: URL) {
      var isDir: ObjCBool = false
      if fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue {
        if let kids = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
          for k in kids where k.hasDirectoryPath {
            // Skip archived legacy-imports folders; they are not active agents
            if k.lastPathComponent == "legacy-imports" { continue }
            slugs.insert(k.lastPathComponent)
          }
        }
      }
    }
    collect(in: root.appendingPathComponent(".clia/agents"))
    // Root-level submodules only
    if let lines = try? String(
      contentsOf: root.appendingPathComponent(".gitmodules"),
      encoding: .utf8
    ) {
      for raw in lines.components(separatedBy: .newlines) {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("path") {
          let parts = line.split(separator: "=", maxSplits: 1).map {
            String($0).trimmingCharacters(in: .whitespaces)
          }
          if parts.count == 2 {
            let sub = root.appendingPathComponent(parts[1]).appendingPathComponent(
              ".clia/agents")
            collect(in: sub)
          }
        }
      }
    }
    return slugs
  }
}
