import ArgumentParser
import Foundation

public enum CoreToolCapability: String {
  case normalizeSchemaApply = "normalize-schema.apply"
  case recoveryRestore = "recovery.restore"
  case cleanupBackupsApply = "cleanup-backups.apply"
  case agencyLogWrite = "agency-log.write"
  case journalAppend = "journal.append"
  case rosterUpdateWrite = "roster-update.write"
  case incidentsActivate = "incidents.activate"
  case incidentsClear = "incidents.clear"
}

public enum ToolUsePolicy {
  struct Rule: Decodable {
    let capability: String
    let when: String?
    let reason: String?
  }

  public static func guardAllowed(_ cap: CoreToolCapability, under root: URL) throws {
    if isDenied(cap, under: root) {
      if let v = ProcessInfo.processInfo.environment["CLIA_TOOL_OVERRIDE"], v == "1" {
        fputs(
          "[policy] override: proceeding with blocked capability '\(cap.rawValue)' via CLIA_TOOL_OVERRIDE=1\n",
          stderr)
        return
      }
      throw ValidationError(
        "TOOL BLOCKED by policy: \(cap.rawValue). Set CLIA_TOOL_OVERRIDE=1 to override (not recommended)."
      )
    }
  }

  public static func isDenied(_ cap: CoreToolCapability, under root: URL) -> Bool {
    let fm = FileManager.default
    let incidentsLock = root.appendingPathComponent(".clia/incidents/recovery.lock")
    let hasLock = fm.fileExists(atPath: incidentsLock.path)
    let incident = root.appendingPathComponent(".clia/incidents/active.json")
    let incidentActive = fm.fileExists(atPath: incident.path)
    let blockedByIncident = blockedToolsFromIncident(at: incident)
    if blockedByIncident.contains(cap.rawValue) { return true }
    // Canonical v4 path only
    let path = root.appendingPathComponent(".clia/workspace.clia.json")
    let denyRules = denyRulesFromWorkspace(at: path)
    for r in denyRules where r.capability == cap.rawValue {
      switch r.when ?? "incidentOrLock" {
      case "always": return true
      case "incident": if incidentActive { return true }
      case "lockOnly": if hasLock { return true }
      case "incidentOrLock": if incidentActive || hasLock { return true }
      default: break
      }
    }
    return false
  }

  private static func denyRulesFromWorkspace(at url: URL) -> [Rule] {
    guard let data = try? Data(contentsOf: url),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let policy = obj["toolPolicy"] as? [String: Any],
      let arr = policy["deny"] as? [Any]
    else { return [] }
    var out: [Rule] = []
    for v in arr {
      if let d = v as? [String: Any], let cap = d["capability"] as? String {
        let when = d["when"] as? String
        let reason = d["reason"] as? String
        out.append(Rule(capability: cap, when: when, reason: reason))
      }
    }
    return out
  }

  private static func blockedToolsFromIncident(at url: URL) -> Set<String> {
    guard let data = try? Data(contentsOf: url),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return [] }
    if let list = obj["blockedTools"] as? [String] { return Set(list) }
    return []
  }
}
