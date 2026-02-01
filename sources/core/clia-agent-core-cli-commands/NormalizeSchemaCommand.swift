import ArgumentParser
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct NormalizeSchemaCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "normalize-schema",
      abstract: "Normalize agent triads to schemaVersion 0.4.0 (carry forward info)")
  }

  public init() {}

  @Option(name: .customLong("slug"), help: "Limit to a single agent slug")
  public var slug: String?

  @Option(name: .customLong("path"), help: "Root path (default: CWD)")
  public var path: String?

  @Flag(name: .customLong("all"), help: "Include all triads under --path")
  public var all: Bool = false

  @Flag(name: .customLong("apply"), help: "Write changes in-place")
  public var apply: Bool = false

  @Flag(name: .customLong("backup"), help: "Write .bak file before applying")
  public var backup: Bool = false

  @Flag(
    name: .customLong("verify"),
    help: "Verify semantic equivalence (typed) before apply; prints per-file status")
  public var verify: Bool = false

  @Flag(name: .customLong("json"), help: "Emit machine-readable JSON for --verify results")
  public var json: Bool = false

  public enum MergeMode: String, ExpressibleByArgument, CaseIterable {
    case preserve, union, flatten
  }
  @Option(
    name: .customLong("merge-mode"),
    help:
      "Array merge for agent/agenda: \(MergeMode.allCases.map { $0.rawValue }.joined(separator: ", "))"
  )
  public var mergeMode: MergeMode = .preserve

  @Flag(
    name: .customLong("i-understand-data-loss"),
    help:
      "Acknowledge potential data/structure loss; required to proceed when risk is detected or non-preserve merge modes are selected"
  )
  public var acknowledgeDataLoss: Bool = false

  public func run() throws {
    let fm = FileManager.default
    let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
    if apply {
      try ToolUsePolicy.guardAllowed(.normalizeSchemaApply, under: root)
    }
    var targets: [URL] = []

    if let slug {
      let dir = root.appendingPathComponent(".clia/agents/\(slug)")
      if fm.fileExists(atPath: dir.path) { targets.append(dir) }
    } else if all {
      let e = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey])
      while let url = e?.nextObject() as? URL {
        if url.lastPathComponent == "agents", url.path.contains("/.clia/") {
          // collect immediate children dirs under agents/
          if let children = try? fm.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey])
          {
            for c in children {
              var isDir: ObjCBool = false
              if fm.fileExists(atPath: c.path, isDirectory: &isDir), isDir.boolValue {
                targets.append(c)
              }
            }
          }
        }
      }
    } else {
      throw ValidationError("Specify --slug <agent> or --all to select targets")
    }

    var changedCount = 0
    var riskDetected = false
    var fileCount = 0
    var verifyResults: [[String: Any]] = []
    for dir in targets.sorted(by: { $0.path < $1.path }) {
      let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
      for f in files where isTriadJSON(f) {
        fileCount += 1
        do {
          let originalData = try Data(contentsOf: f)
          guard let obj = try JSONSerialization.jsonObject(with: originalData) as? [String: Any]
          else { continue }
          var upgraded = obj
          let kind = docKind(for: f)
          normalize(&upgraded, kind: kind)
          // Non-destructive policy: no structural array flattening or unions are applied.

          // Detect structural change risk (should remain false under non-destructive policy)
          let structuralRisk =
            isStructuralRisk(original: obj, upgraded: upgraded, kind: kind)
            || (mergeMode != .preserve)
          if structuralRisk { riskDetected = true }
          // Force schemaVersion to 0.4.0
          upgraded["schemaVersion"] = TriadSchemaVersion.current
          let finalData = try JSONSerialization.data(
            withJSONObject: upgraded, options: JSON.Formatting.humanOptions)

          // Optional semantic verification (typed equivalence)
          if verify {
            let canonOriginal = canonicalTyped(from: originalData, kind: kind)
            let canonNormalized = canonicalTyped(from: finalData, kind: kind)
            let ok =
              (canonOriginal != nil && canonNormalized != nil && canonOriginal == canonNormalized)
            if json {
              let entry: [String: Any] = [
                "path": f.path,
                "kind": String(describing: kind),
                "semanticsEqual": ok,
              ]
              verifyResults.append(entry)
            } else {
              if ok {
                print("[verify] ok semantics-equal: \(f.path)")
              } else {
                fputs("[verify] warn: semantic mismatch or decode failure at \(f.path)\n", stderr)
              }
            }
          }
          if finalData != pretty(originalData) {
            changedCount += 1
            print("[normalize] \(f.path) → will update")
            if apply {
              if structuralRisk && !acknowledgeDataLoss {
                fputs("\n==================== DATA LOSS RISK ====================\n", stderr)
                fputs(
                  "normalize-schema detected potential structural changes or a non-preserve merge mode.\n",
                  stderr)
                fputs("Refusing to apply without --i-understand-data-loss.\n", stderr)
                fputs("File: \(f.path)\n", stderr)
                throw ValidationError("data-loss risk without acknowledgment")
              }
              if backup {
                let bak = f.deletingLastPathComponent().appendingPathComponent(
                  f.lastPathComponent + ".bak")
                try? fm.removeItem(at: bak)
                try originalData.write(to: bak)
              }
              // Write normalized JSON via shared writer with human-friendly options
              if let upgradedObj = try? JSONSerialization.jsonObject(with: finalData) {
                try JSON.FileWriter.writeJSONObject(
                  upgradedObj, to: f, options: JSON.Formatting.humanOptions)
              } else {
                try finalData.write(to: f, options: .atomic)
              }
            } else {
              // dry-run: print a short summary
              printDiffPreview(original: originalData, updated: finalData, path: f.path)
            }
          }
        } catch {
          fputs("[normalize] error: \(f.path): \(error)\n", stderr)
        }
      }
    }
    if riskDetected && !apply {
      fputs(
        "[warn] normalize-schema: structural risk detected in planned changes; no writes were made.\n",
        stderr)
    }
    if (mergeMode != .preserve) && !acknowledgeDataLoss {
      fputs("\n==================== DATA LOSS RISK ====================\n", stderr)
      fputs(
        "merge-mode is \(mergeMode). This is considered risky and may drop or reshape data.\n",
        stderr)
      fputs(
        "Re-run with --i-understand-data-loss to proceed, or use --merge-mode preserve.\n", stderr)
    }
    if verify && json {
      if let data = try? JSONSerialization.data(
        withJSONObject: verifyResults, options: [.prettyPrinted, .sortedKeys])
      {
        if let s = String(data: data, encoding: .utf8) { print(s) }
      }
    } else {
      let mode = apply ? "applied" : "planned"
      print("[normalize] \(mode) changes: \(changedCount) file(s) out of \(fileCount)")
    }
  }

  private func isTriadJSON(_ url: URL) -> Bool {
    let name = url.lastPathComponent
    guard name.hasSuffix(".json") else { return false }
    return name.contains(".agent.") || name.contains(".agenda.") || name.contains(".agency.")
  }

  private enum Kind { case agent, agenda, agency }
  private func docKind(for url: URL) -> Kind {
    let name = url.lastPathComponent
    if name.contains(".agent.") { return .agent }
    if name.contains(".agenda.") { return .agenda }
    return .agency
  }

  private func canonicalTyped(from data: Data, kind: Kind) -> Data? {
    let dec = JSONDecoder()
    let enc = JSONEncoder()
    enc.outputFormatting = [.sortedKeys]
    switch kind {
    case .agent:
      if let v = try? dec.decode(AgentDoc.self, from: data) { return try? enc.encode(v) }
      if var obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
        normalize(&obj, kind: .agent)
        if let normalized = try? JSONSerialization.data(withJSONObject: obj),
          let v = try? dec.decode(AgentDoc.self, from: normalized)
        {
          return try? enc.encode(v)
        }
      }
    case .agenda:
      if let v = try? dec.decode(AgendaDoc.self, from: data) { return try? enc.encode(v) }
      if var obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
        normalize(&obj, kind: .agenda)
        if let normalized = try? JSONSerialization.data(withJSONObject: obj),
          let v = try? dec.decode(AgendaDoc.self, from: normalized)
        {
          return try? enc.encode(v)
        }
      }
    case .agency:
      if let v = try? dec.decode(AgencyDoc.self, from: data) { return try? enc.encode(v) }
      if var obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
        normalize(&obj, kind: .agency)
        if let normalized = try? JSONSerialization.data(withJSONObject: obj),
          let v = try? dec.decode(AgencyDoc.self, from: normalized)
        {
          return try? enc.encode(v)
        }
      }
    }
    return nil
  }

  private func normalize(_ doc: inout [String: Any], kind: Kind) {
    // schemaVersion key is required going forward (no legacy alias handling)
    doc["schemaVersion"] = TriadSchemaVersion.current
    // Hoist sourcePath from extensions variants
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
    // sections: [String] → [Section]
    if let arr = doc["sections"] as? [Any] {
      if arr.first is String {
        let strings = arr.compactMap { $0 as? String }
        doc["sections"] = sectionsFromFlat(strings)
      }
    }
    // checklists: [String] → [Checklist]
    if let arr = doc["checklists"] as? [Any] {
      if arr.first is String {
        let strings = arr.compactMap { $0 as? String }
        let items = strings.map { ["text": $0, "level": "required"] as [String: Any] }
        doc["checklists"] = [["items": items]]
      }
    }
    // notes.object unwrap + blocks typing
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
    // Preserve sections/checklists structure for all triad kinds (non-destructive).
    // role fallback to slug when missing/empty
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

  // MARK: - Union helpers
  private func unionSections(existing: Any?, normalized: Any?) -> [String]? {
    let a = flattenSections(existing)
    let b = flattenSections(normalized)
    if a == nil && b == nil { return nil }
    return unionStringsLists([a ?? [], b ?? []])
  }
  private func unionStrings(existing: Any?, normalized: Any?) -> [String]? {
    let a = flattenStrings(existing)
    let b = flattenStrings(normalized)
    if a == nil && b == nil { return nil }
    return unionStringsLists([a ?? [], b ?? []])
  }

  private func flattenSections(_ v: Any?) -> [String]? {
    guard let v else { return nil }
    if let s = v as? [String] { return s }
    if let objs = v as? [[String: Any]] {
      var out: [String] = []
      for section in objs {
        let title = (section["title"] as? String) ?? (section["slug"] as? String) ?? ""
        if let items = section["items"] as? [Any], !items.isEmpty {
          for vv in items {
            if let ss = vv as? String { out.append(title.isEmpty ? ss : "\(title): \(ss)") }
          }
        } else if !title.isEmpty {
          out.append(title)
        }
      }
      return out
    }
    if let any = v as? [Any] { return any.compactMap { $0 as? String } }
    return nil
  }
  private func flattenStrings(_ v: Any?) -> [String]? {
    guard let v else { return nil }
    if let s = v as? [String] { return s }
    if let objs = v as? [[String: Any]] {
      var out: [String] = []
      for entry in objs {
        if let t = entry["title"] as? String, !t.isEmpty { out.append(t) }
        if let items = entry["items"] as? [Any] {
          for vv in items { if let ss = vv as? String { out.append(ss) } }
        }
      }
      return out
    }
    if let any = v as? [Any] { return any.compactMap { $0 as? String } }
    return nil
  }

  private func unionStringsLists(_ lists: [[String]]) -> [String] {
    var seen = Set<String>()
    var out: [String] = []
    for arr in lists {
      for s in arr where !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        if seen.insert(s).inserted { out.append(s) }
      }
    }
    return out
  }

  // MARK: - Risk detection
  private func isStructuralRisk(original: [String: Any], upgraded: [String: Any], kind: Kind)
    -> Bool
  {
    // If types differ or array contents differ for structural keys, mark risk
    return differs(key: "sections", original: original, upgraded: upgraded)
      || differs(key: "checklists", original: original, upgraded: upgraded)
  }

  private func differs(key: String, original: [String: Any], upgraded: [String: Any]) -> Bool {
    let a = original[key]
    let b = upgraded[key]
    // Consider absent vs empty as equal for safety
    if a == nil && b == nil { return false }
    if let aa = a as? [Any], let bb = b as? [Any] {
      return !jsonArrayEqual(aa, bb)
    }
    // Type changed is risk
    return (a != nil) != (b != nil)
  }

  private func jsonArrayEqual(_ a: [Any], _ b: [Any]) -> Bool {
    // Best-effort: compare serialized JSON strings with sorted keys where possible
    if JSONSerialization.isValidJSONObject(a), JSONSerialization.isValidJSONObject(b) {
      let da = try? JSONSerialization.data(withJSONObject: a, options: [.sortedKeys])
      let db = try? JSONSerialization.data(withJSONObject: b, options: [.sortedKeys])
      return da == db
    }
    return a.count == b.count
  }

  private func pretty(_ data: Data) -> Data {
    // normalize whitespace for comparison
    if let obj = try? JSONSerialization.jsonObject(with: data),
      let out = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
    {
      return out
    }
    return data
  }

  private func printDiffPreview(original: Data, updated: Data, path: String) {
    guard let a = String(data: pretty(original), encoding: .utf8),
      let b = String(data: updated, encoding: .utf8)
    else { return }
    let aLines = a.components(separatedBy: "\n")
    let bLines = b.components(separatedBy: "\n")
    print("--- \(path)")
    print("+++ \(path) (normalized)")
    let max = min(200, max(aLines.count, bLines.count))
    for i in 0..<max {
      let l = i < aLines.count ? aLines[i] : ""
      let r = i < bLines.count ? bLines[i] : ""
      if l != r {
        if !l.isEmpty { print("- \(l)") }
        if !r.isEmpty { print("+ \(r)") }
      }
    }
    if aLines.count > max || bLines.count > max { print("… (diff truncated)") }
  }
}
