import CLIACore
import CLIACoreModels
import Foundation

public enum ConversationHeader {
  public struct Lines {
    public var line1: String
    public var line2: String
    public var line3: String?
    public init(line1: String, line2: String, line3: String? = nil) {
      self.line1 = line1
      self.line2 = line2
      self.line3 = line3
    }
  }

  /// Render standard 3-line conversation header (third line shows active incident when present).
  /// - Parameters:
  ///   - slug: agent slug used to resolve defaults from triads
  ///   - root: starting directory (repo root will be located by ascending)
  ///   - mode: optional mode override (falls back to triad defaults or "planning")
  ///   - title: optional title override (falls back to triad defaults or "Untitled")
  public static func render(
    slug: String, under root: URL, mode: String? = nil, title: String? = nil
  ) -> Lines? {
    let repoRoot = findRepoRoot(startingAt: root) ?? root
    // Read header from workspace.clia.json; when absent, emit no header
    guard let ws = try? WorkspaceConfig.load(under: repoRoot), let hdr = ws.header else {
      return nil
    }
    let (line1Tpl, line2Tpl, attendeesFormat, delimiter, defaults) = extractHeaderTemplates(
      from: hdr)
    let modeVal = mode ?? defaults["mode"] ?? "planning"
    // Dynamic title override: if .clia/tmp/header-title.txt exists and has content, prefer it
    let dynamicTitle: String? = {
      let path = repoRoot.appendingPathComponent(".clia/tmp/header-title.txt")
      if let data = try? Data(contentsOf: path),
        let s = String(data: data, encoding: .utf8)?.trimmingCharacters(
          in: .whitespacesAndNewlines),
        !s.isEmpty
      {
        return s
      }
      return nil
    }()
    let titleVal = title ?? dynamicTitle ?? (defaults["title"] ?? "Untitled")
    let attendeeEmojis = defaults["attendeeEmojis"] ?? ""
    let attendees = (defaults["attendees"] ?? "").split(separator: ",").map {
      $0.trimmingCharacters(in: .whitespaces)
    }
    let attendeesRendered = attendees.map { cs in
      let slugPart: String = {
        if let dot = cs.lastIndex(of: ".") { return String(cs[cs.index(after: dot)...]) }
        if let at = cs.lastIndex(of: "@") { return String(cs[cs.index(after: at)...]) }
        return cs
      }()
      let displayRole = resolveDisplayRole(slug: slugPart, under: repoRoot)
      return
        attendeesFormat
        .replacingOccurrences(of: "{role}", with: displayRole)
        .replacingOccurrences(of: "{slug}", with: slugPart)
        .replacingOccurrences(of: "{contribs}", with: "")
    }.joined(separator: delimiter)

    let line1 =
      line1Tpl
      .replacingOccurrences(of: "{mode}", with: modeVal)
      .replacingOccurrences(of: "{title}", with: titleVal)
    let line2 =
      line2Tpl
      .replacingOccurrences(of: "{attendeeEmojis}", with: attendeeEmojis)
      .replacingOccurrences(of: "{attendees}", with: attendeesRendered)

    var line3: String? = nil
    if let active = loadActiveIncident(at: repoRoot) {
      line3 = active.bannerText
    }
    return .init(line1: line1, line2: line2, line3: line3)
  }

  // MARK: - Helpers

  private static func extractHeaderTemplates(from hdr: ResponseHeader) -> (
    String, String, String, String, [String: String]
  ) {
    var line1Tpl = "[🧭: %{mode}] [💡| {title}]"
    var line2Tpl = "[{attendeeEmojis}| {attendees}]"
    var attendeesFormat = "{role} (^{slug})"
    var delimiter = " · "
    var defaults: [String: String] = [:]
    if let r = hdr.rendering {
      if let t = r.templates {
        if let v = t.line1 { line1Tpl = v }
        if let v = t.line2 { line2Tpl = v }
      }
      if let v = r.attendeesFormat { attendeesFormat = v }
      if let v = r.delimiter { delimiter = v }
    }
    if let d = hdr.defaults {
      if let v = d.mode { defaults["mode"] = v }
      if let v = d.title { defaults["title"] = v }
      if let v = d.attendeeEmojis { defaults["attendeeEmojis"] = v }
      if let arr = d.attendees { defaults["attendees"] = arr.joined(separator: ", ") }
    }
    return (line1Tpl, line2Tpl, attendeesFormat, delimiter, defaults)
  }

  private static func resolveDisplayRole(slug: String, under root: URL) -> String {
    let fm = FileManager.default
    let dir = root.appendingPathComponent(".clia/agents/\(slug)")
    guard
      let file = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        .first(where: { $0.lastPathComponent.contains(".agent.") && $0.pathExtension == "json" })
    else { return slug }
    guard let data = fm.contents(atPath: file.path) else { return slug }
    if let doc = try? JSONDecoder().decode(AgentDoc.self, from: data),
      let r = doc.role, !r.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return r
    }
    return slug
  }

  private static func findRepoRoot(startingAt url: URL) -> URL? {
    let fm = FileManager.default
    var cur = url
    while true {
      let agency = cur.appendingPathComponent("AGENCY.md")
      let wrk = cur.appendingPathComponent(".wrkstrm")
      if fm.fileExists(atPath: agency.path) || fm.fileExists(atPath: wrk.path) { return cur }
      let next = cur.deletingLastPathComponent()
      if next.path == cur.path { break }
      cur = next
    }
    return nil
  }

  private static func loadActiveIncident(at root: URL) -> Incident? {
    let fm = FileManager.default
    let url = root.appendingPathComponent(".clia/incidents/active.json")
    guard fm.fileExists(atPath: url.path), let data = fm.contents(atPath: url.path) else {
      return nil
    }
    return try? JSONDecoder().decode(Incident.self, from: data)
  }
}
