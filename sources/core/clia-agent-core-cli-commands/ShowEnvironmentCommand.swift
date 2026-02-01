import ArgumentParser
import CLIAAgentCore
import CLIACore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct ShowEnvironmentCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "show-environment",
      abstract:
        "Print workspace environment: header, directives, preferences, policy, git/sharing, and incident"
    )
  }

  public init() {}

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  public enum Format: String, ExpressibleByArgument, CaseIterable { case json, text, md }
  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  @Option(
    name: .customLong("parts"),
    help:
      "Comma-separated parts: header,directives,preferences,policy,git,sharing,incident (default: all)"
  )
  public var partsCSV: String = ""

  // Header preview overrides (do not mutate config)
  @Option(name: .customLong("mode")) public var mode: String?
  @Option(name: .customLong("title")) public var title: String?
  @Option(name: .customLong("attendees")) public var attendeesOverride: String?
  @Option(name: .customLong("attendee-emojis")) public var attendeeEmojisOverride: String?
  @Option(name: .customLong("delimiter")) public var delimiterOverride: String?

  public func run() throws {
    let start = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    let root = WriteTargetResolver.resolveRepoRoot(startingAt: start) ?? start
    let cfg = try WorkspaceConfig.load(under: root)
    let wanted = wantedParts()
    let workspaceSemanticVersion = WorkspaceSchemaVersion.current

    // Build header sample lines (honor dynamic title override file if present)
    let lines: [String] = {
      guard let hdr = cfg.header else { return [] }
      let t = hdr.rendering?.templates
      let line1Tpl = t?.line1 ?? "[🧭: %{mode}] [💡| {title}]"
      let line2Tpl = t?.line2 ?? "[{attendeeEmojis}| {attendees}]"
      let attendeesFormat = hdr.rendering?.attendeesFormat ?? "{role} (^{slug})"
      let delimiter = delimiterOverride ?? (hdr.rendering?.delimiter ?? " · ")
      let defaults = hdr.defaults
      let modeVal = mode ?? defaults?.mode ?? "planning"
      // Dynamic title override: read .clia/tmp/header-title.txt when present
      let dynamicTitle: String? = {
        let overridePath = root.appendingPathComponent(".clia/tmp/header-title.txt")
        if let data = try? Data(contentsOf: overridePath),
          let s = String(data: data, encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines),
          !s.isEmpty
        {
          return s
        }
        return nil
      }()
      let titleVal = title ?? dynamicTitle ?? (defaults?.title ?? "Untitled")
      let attendeeEmojis = attendeeEmojisOverride ?? (defaults?.attendeeEmojis ?? "")
      let attendees =
        attendeesOverride
        .map { $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        ?? (defaults?.attendees ?? [])
      let renderedAttendees = attendees.map { cs in
        let slugPart: String = {
          if let dot = cs.lastIndex(of: ".") { return String(cs[cs.index(after: dot)...]) }
          if let at = cs.lastIndex(of: "@") { return String(cs[cs.index(after: at)...]) }
          return cs
        }()
        let displayRole = resolveDisplayRole(slug: slugPart, under: root)
        return
          attendeesFormat
          .replacingOccurrences(of: "{role}", with: displayRole)
          .replacingOccurrences(of: "{slug}", with: slugPart)
      }.joined(separator: delimiter)
      let l1 = line1Tpl.replacingOccurrences(of: "{mode}", with: modeVal).replacingOccurrences(
        of: "{title}", with: titleVal)
      let l2 = line2Tpl.replacingOccurrences(of: "{attendeeEmojis}", with: attendeeEmojis)
        .replacingOccurrences(of: "{attendees}", with: renderedAttendees)
      var out = [l1, l2]
      if let incident = loadActiveIncident(at: root) { out.append(incident.bannerText) }
      return out
    }()

    switch format {
    case .json:
      struct Payload: Codable {
        var ok: Bool
        var workspaceVersion: String
        var header: ResponseHeader?
        var sample: [String]
        var directives: DirectivesProfiler.Profile?
        var incident: Incident?
      }
      let directivesProfile =
        wanted.contains("directives")
        ? try DirectivesProfiler.profile(slug: "codex", root: root)
        : nil
      let payload = Payload(
        ok: true,
        workspaceVersion: workspaceSemanticVersion,
        header: wanted.contains("header") ? cfg.header : nil,
        sample: wanted.contains("header") ? lines : [],
        directives: directivesProfile,
        incident: wanted.contains("incident") ? loadActiveIncident(at: root) : nil
      )
      let enc = JSON.Formatting.humanEncoder
      print(String(decoding: try enc.encode(payload), as: UTF8.self))
    case .text:
      print("Workspace \(workspaceSemanticVersion) (v4)")
      if wanted.contains("header") {
        if cfg.header != nil {
          print("header:")
          if lines.count >= 2 {
            print(lines[0])
            print(lines[1])
          }
          if lines.count >= 3 { print(lines[2]) }
        } else {
          print("header: (no header configured)")
        }
      }
      if wanted.contains("directives") {
        print("\n-- directives --")
        let txt = try DirectivesProfiler.render(slug: "codex", root: root, format: "text")
        print(txt)
      }
      if wanted.contains("preferences"), let p = cfg.preferences { print("\npreferences: \(p)") }
      if wanted.contains("policy"), let p = cfg.policy { print("\npolicy: \(p)") }
      if wanted.contains("git"), let g = cfg.git { print("\ngit: \(g)") }
      if wanted.contains("sharing"), let s = cfg.sharing { print("\nsharing: \(s)") }
      if wanted.contains("incident"), let i = loadActiveIncident(at: root) {
        print("\nincident: \(i.bannerText)")
      }
    case .md:
      print("# Environment Overview — Workspace \(workspaceSemanticVersion) (v4)\n")
      if wanted.contains("header") {
        print("## Header")
        if lines.isEmpty {
          print("(no header configured)\n")
        } else {
          print(lines[0])
          print(lines[1])
          if lines.count >= 3 { print(lines[2]) }
          print("")
        }
      }
      if wanted.contains("directives") {
        print("## Directives\n")
        let md = try DirectivesProfiler.render(slug: "codex", root: root, format: "md")
        print(md)
      }
    }
  }

  private func resolveDisplayRole(slug: String, under root: URL) -> String {
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

  private func wantedParts() -> Set<String> {
    let all: Set<String> = [
      "header", "directives", "preferences", "policy", "git", "sharing", "incident",
    ]
    let raw = partsCSV.split(separator: ",").map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    let chosen = Set(raw.filter { !$0.isEmpty })
    return chosen.isEmpty ? all : all.intersection(chosen)
  }

  private func loadActiveIncident(at root: URL) -> Incident? {
    let fm = FileManager.default
    let url = root.appendingPathComponent(".clia/incidents/active.json")
    guard fm.fileExists(atPath: url.path), let data = fm.contents(atPath: url.path) else {
      return nil
    }
    return try? JSONDecoder().decode(Incident.self, from: data)
  }
}
