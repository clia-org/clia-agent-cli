import ArgumentParser
import CLIAAgentCore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct ToolPolicyCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "policy",
      abstract: "Show effective tool policy (rules, incident/lock, and blocked capabilities)")
  }

  public enum Format: String, ExpressibleByArgument, CaseIterable { case text, json }

  @Option(name: .customLong("path"), help: "Root path (default: CWD)")
  public var path: String?

  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  public init() {}

  public func run() throws {
    let fm = FileManager.default
    let start = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
    let root = WriteTargetResolver.resolveRepoRoot(startingAt: start) ?? start
    let incidentsLock = root.appendingPathComponent(".clia/incidents/recovery.lock")
    let hasLock = fm.fileExists(atPath: incidentsLock.path)
    let incidentURL = root.appendingPathComponent(".clia/incidents/active.json")
    let incident: Incident? = {
      guard let data = try? Data(contentsOf: incidentURL) else { return nil }
      return try? JSONDecoder().decode(Incident.self, from: data)
    }()
    let blocked: Set<String> = Set(incident?.blockedTools ?? [])
    // Canonical v4 path only
    let rules = denyRulesFromWorkspace(
      at: root.appendingPathComponent(".clia/workspace.clia.json"))
    let caps: [CoreToolCapability] = [
      .normalizeSchemaApply,
      .recoveryRestore,
      .cleanupBackupsApply,
      .agencyLogWrite,
      .journalAppend,
      .rosterUpdateWrite,
    ]
    var effective: [String: Bool] = [:]
    for c in caps { effective[c.rawValue] = ToolUsePolicy.isDenied(c, under: root) }

    switch format {
    case .text:
      print("Policy status:")
      print("- lock: \(hasLock ? "present" : "absent")")
      if let inc = incident {
        let sev = inc.severity.string
        let title = inc.title
        print("- incident: active (\(sev) — \(title))")
      } else {
        print("- incident: none")
      }
      if !blocked.isEmpty {
        print("- incident.blockedTools: \(blocked.sorted().joined(separator: ", "))")
      }
      print("Rules (deny):")
      if rules.isEmpty {
        print("- (none)")
      } else {
        for r in rules {
          print("- \(r.capability) when=\(r.when ?? "incidentOrLock") — \(r.reason ?? "")")
        }
      }
      print("Effective blocks:")
      for c in caps {
        let b = effective[c.rawValue] == true
        print("- \(c.rawValue): \(b ? "blocked" : "allowed")")
      }
    case .json:
      var out: [String: Any] = [:]
      out["lock"] = hasLock
      if let inc = incident {
        // Echo minimal banner in JSON for consistency
        out["incident"] = [
          "id": inc.id,
          "title": inc.title,
          "severity": inc.severity.string,
          "status": inc.status,
          "owner": inc.owner,
          "started": inc.started,
        ]
      }
      out["rules"] = rules.map {
        ["capability": $0.capability, "when": $0.when as Any, "reason": $0.reason as Any]
      }
      out["effective"] = effective
      let data = try JSONSerialization.data(
        withJSONObject: out, options: JSON.Formatting.humanOptions)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    }
  }
}

// Local helpers mirroring ToolUsePolicy internals for richer presentation
private func denyRulesFromWorkspace(at url: URL) -> [ToolUsePolicy.Rule] {
  let fm = FileManager.default
  guard fm.fileExists(atPath: url.path),
    let data = try? Data(contentsOf: url),
    let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
    let policy = obj["toolPolicy"] as? [String: Any],
    let arr = policy["deny"] as? [Any]
  else { return [] }
  var out: [ToolUsePolicy.Rule] = []
  for v in arr {
    if let d = v as? [String: Any], let cap = d["capability"] as? String {
      let when = d["when"] as? String
      let reason = d["reason"] as? String
      out.append(.init(capability: cap, when: when, reason: reason))
    }
  }
  return out
}
