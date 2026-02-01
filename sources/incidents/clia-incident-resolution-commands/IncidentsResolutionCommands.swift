import ArgumentParser
import CLIAIncidentCoreCommands
import Foundation

public struct IncidentsResolutionGroup: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "incidents", abstract: "Incident resolution (writes)",
      subcommands: [New.self, Activate.self, Clear.self])
  }
  public init() {}
}

extension IncidentsResolutionGroup {
  public struct New: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "new", abstract: "Create a new incident report from the standard template")
    }
    public init() {}

    @Option(name: .customLong("title"), help: "Incident title (short, imperative)")
    public var title: String

    @Option(name: .customLong("owner"), help: "Owning agent directory (default: patch)")
    public var owner: String = "patch"

    @Option(name: .customLong("severity"), help: "Severity S0–S3 (default: S1)")
    public var severity: String = "S1"

    @Option(name: .customLong("service"), help: "Impacted service or area (free text)")
    public var service: String = ""

    @Option(name: .customLong("status"), help: "Initial status (default: active)")
    public var status: String = "active"

    @Option(name: .customLong("path"), help: "Repo root (default: CWD)")
    public var path: String?

    public func run() throws {
      let fm = FileManager.default
      let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      let now = Date()
      let dateStr = ISO8601DateFormatter().string(from: now)
      let day = String(dateStr.prefix(10))
      let slug = makeSlug(title)
      let ownerDir = root.appendingPathComponent(".clia/incidents/\(owner)")
      try fm.createDirectory(at: ownerDir, withIntermediateDirectories: true)
      let file = ownerDir.appendingPathComponent("\(day)-\(slug).md")
      let id = "\(day)-\(slug)"
      let svc = service.isEmpty ? "(set service)" : service
      let body = renderTemplate(
        id: id, title: title, severity: severity, service: svc, status: status, nowISO: dateStr)
      try body.data(using: .utf8)?.write(to: file)
      print(file.path)
    }

    private func makeSlug(_ s: String) -> String {
      let lower = s.lowercased()
      let allowed = lower.map { c -> Character in
        if ("a"..."z").contains(c) || ("0"..."9").contains(c) { return c }
        return "-"
      }
      var slug = String(allowed)
      while slug.contains("--") { slug = slug.replacingOccurrences(of: "--", with: "-") }
      slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
      if slug.isEmpty { slug = "incident" }
      return slug
    }

    private func renderTemplate(
      id: String, title: String, severity: String, service: String, status: String, nowISO: String
    ) -> String {
      return """
        # Incident: \(title)

        - id: \(id)
        - service: \(service)
        - severity: \(severity)
        - status: \(status)
        - started: \(nowISO)
        - detected: \(nowISO)
        - resolved: (TBD)
        - duration: (TBD)
        - reporters: patch
        - owners: patch

        ## Summary

        (One-paragraph overview in plain facts.)

        ## Impact

        - (What broke) 
        - (Blast radius: file count/areas)
        - (User/operator impact)

        ## Affected Components

        - (List paths, CLIs, services)

        ## Timeline (PT)

        - (hh:mm) — (event)

        ## Root Cause

        (Why it happened; what assumptions failed.)

        ## Detection

        (How we noticed; what alerts should have fired.)

        ## Response

        - (Immediate actions)
        - (Code/config changes)

        ## Resolution

        (How we fixed/stabilized; what remains.)

        ## Preventive Actions (CAPA)

        - Guardrails
          - (verify, dry-run, scope gating, structural risk)
        - Tests
          - (new tests)
        - Docs
          - (policy, runbooks)
        - Tooling
          - (recovery commands, manifests)

        ## Verification

        (How to confirm fix; commands/tests.)

        ## Artifacts & References

        - (links/paths)

        ## Open Questions

        - (follow-ups)
        """
    }
  }
  public struct Activate: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(
        commandName: "activate", abstract: "Mark an incident as ACTIVE and write affected areas")
    }
    public init() {}

    @Option(name: .customLong("id"), help: "Incident id (e.g., YYYY-MM-DD-slug)")
    public var id: String

    @Option(name: .customLong("title"), help: "Short incident title")
    public var title: String

    @Option(name: .customLong("severity"), help: "S0–S3")
    public var severity: String = "S1"

    @Option(name: .customLong("owner"), help: "Owning agent (default: patch)")
    public var owner: String = "patch"

    @Option(name: .customLong("summary"), help: "One-line summary (optional)")
    public var summary: String?

    @Option(
      name: .customLong("affected"), parsing: .upToNextOption,
      help: "Affected areas (repeatable path prefixes/globs)")
    public var affected: [String] = []

    @Option(
      name: .customLong("block"), parsing: .upToNextOption, help: "Do-not-modify areas (repeatable)"
    )
    public var block: [String] = []

    @Option(
      name: .customLong("blocked-tool"), parsing: .upToNextOption,
      help: "Blocked tool capabilities (repeatable)")
    public var blockedTools: [String] = []

    @Option(
      name: .customLong("link"), parsing: .upToNextOption,
      help: "Link entry as 'title=url' or 'url' (repeatable)")
    public var linkPairs: [String] = []

    @Option(name: .customLong("path"), help: "Repo root (default: CWD)")
    public var path: String?

    public func run() throws {
      let fm = FileManager.default
      let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      let activeURL = root.appendingPathComponent(".clia/incidents/active.json")
      try fm.createDirectory(
        at: activeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      let now = ISO8601DateFormatter().string(from: Date())
      let payload: [String: Any?] = [
        "id": id,
        "title": title,
        "severity": severity,
        "status": "active",
        "owner": owner,
        "started": now,
        "summary": summary,
        "affectedPaths": affected,
        "doNotModify": block,
        "blockedTools": blockedTools.isEmpty ? nil : blockedTools,
        "links": makeLinks(from: linkPairs),
      ]
      // Remove nils for JSONSerialization safety
      var cleaned: [String: Any] = [:]
      for (k, v) in payload { if let v = v { cleaned[k] = v } }
      let data = try JSONSerialization.data(
        withJSONObject: cleaned, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
      try data.write(to: activeURL, options: .atomic)
      print(activeURL.path)
    }

    private func makeLinks(from pairs: [String]) -> [[String: String]]? {
      var out: [[String: String]] = []
      for p in pairs {
        if let eq = p.firstIndex(of: "=") {
          let title = String(p[..<eq]).trimmingCharacters(in: .whitespaces)
          let url = String(p[p.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
          if !url.isEmpty { out.append(["title": title, "url": url]) }
        } else {
          let url = p.trimmingCharacters(in: .whitespaces)
          if !url.isEmpty { out.append(["url": url]) }
        }
      }
      return out.isEmpty ? nil : out
    }
  }
  public struct Clear: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "clear", abstract: "Clear active incident banner")
    }
    public init() {}
    @Option(name: .customLong("path"), help: "Repo root (default: CWD)")
    public var path: String?
    public func run() throws {
      let fm = FileManager.default
      let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      let activeURL = root.appendingPathComponent(".clia/incidents/active.json")
      if fm.fileExists(atPath: activeURL.path) {
        try fm.removeItem(at: activeURL)
        print("cleared: \(activeURL.path)")
      } else {
        print("no active incident at \(activeURL.path)")
      }
    }
  }
}
