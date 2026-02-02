import ArgumentParser
import CLIAAgentCore
import CLIACore
import Foundation

public struct TriadsCommandGroup: AsyncParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "triads",
      abstract: "Triad maintenance (agent/agency/agenda): log, normalize, render, aggregate",
      subcommands: [Agency.self, Normalize.self, Render.self, Aggregate.self]
    )
  }

  public init() {}
}

extension TriadsCommandGroup {
  public struct Agency: AsyncParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "agency", abstract: "Agency triad operations", subcommands: [Log.self])
    }

    public init() {}

    public struct Log: AsyncParsableCommand {
      public static var configuration: CommandConfiguration {
        .init(
          commandName: "log",
          abstract: "Append a 0.4.0 ContributionEntry to *.agency.triad.json"
        )
      }

      public init() {}

      @Option(
        name: [.customLong("agent"), .customShort("a")], parsing: .upToNextOption,
        help: "Agent slug(s) (repeatable)")
      public var agents: [String] = []

      @Option(name: .customLong("kind"), help: "Entry kind (log|request|decision)")
      public var kind: String = "log"

      @Option(name: .customLong("title"), help: "Optional title")
      public var title: String?

      @Option(name: .customLong("summary"), help: "Summary line (required)")
      public var summary: String

      @Option(name: .customLong("details"), help: "Optional details body")
      public var details: String?

      @Option(
        name: .customLong("detail"), parsing: .upToNextOption,
        help: "Optional detail line (repeatable)")
      public var detailItems: [String] = []

      @Option(name: .customLong("participants"), help: "Comma-separated agent slugs involved")
      public var participantsCSV: String = ""

      @Option(name: .customLong("tags"), help: "Comma-separated tags to include")
      public var tagsCSV: String = ""

      @Option(
        name: .customLong("link"), parsing: .upToNextOption,
        help: "Link ref: 'href' or 'href|kind|title' (repeatable)")
      public var linkArgs: [String] = []

      @Option(
        name: .customLong("contrib"), parsing: .upToNextOption,
        help: "Contribution 'by=<slug>,type=<type>,evidence=<text>[,weight=<n>]' (repeatable)")
      public var contribArgs: [String] = []

      @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
      public var path: String?

      @Flag(name: .customLong("create-if-missing"), help: "Create a minimal agency file if missing")
      public var createIfMissing: Bool = false

      @Flag(
        name: .customLong("upsert"),
        help: "Upsert by (date + kind/title) instead of always appending")
      public var upsert: Bool = false

      public mutating func run() async throws {
        let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
        try ToolUsePolicy.guardAllowed(.agencyLogWrite, under: cwd)
        precondition(!agents.isEmpty, "--agent is required at least once")
        let participants = participantsCSV.split(separator: ",").map {
          String($0).trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
        let tags = tagsCSV.split(separator: ",").map {
          String($0).trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
        let ts = ISO8601DateFormatter().string(from: Date())
        let parsedContribs: [AgencyContributionArg] = contribArgs.compactMap { arg in
          var by: String?
          var type: String?
          var evidence: String?
          var weight: Double?
          for pair in arg.split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let k = parts[0].trimmingCharacters(in: .whitespaces)
            let v = parts[1].trimmingCharacters(in: .whitespaces)
            switch k {
            case "by": by = v
            case "type": type = v
            case "evidence": evidence = v
            case "weight": weight = Double(v)
            default: break
            }
          }
          if let by, let type, let evidence {
            return AgencyContributionArg(by: by, type: type, evidence: evidence, weight: weight)
          }
          return nil
        }
        for slug in agents {
          _ = try AgencyLogCore.apply(
            startingAt: cwd,
            slug: slug,
            summary: summary,
            kind: kind,
            title: title,
            detailItems: detailItems,
            detailsText: details,
            participants: participants,
            tags: tags,
            linkArgs: linkArgs,
            contributionArgs: parsedContribs,
            createIfMissing: createIfMissing,
            upsert: upsert,
            timestamp: ts
          )
          print(
            "[triads agency log] wrote entry to .clia/agents/\(slug)/\(slug)@sample.agency.triad.json"
          )
        }
      }
    }

    // removed per-request: sorting moved under triads normalize
  }
}

extension TriadsCommandGroup {
  public struct Normalize: AsyncParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(
        commandName: "normalize",
        abstract: "Normalize triads (format/order) for a kind: agency|agenda|agent")
    }

    public init() {}

    public enum Kind: String, ExpressibleByArgument, CaseIterable { case agency, agenda, agent }

    @Option(
      name: .customLong("kind"),
      help: "Triad kind: \(Kind.allCases.map{$0.rawValue}.joined(separator: ", "))")
    public var kind: Kind = .agency

    @Option(name: .customLong("slug"), help: "Agent slug (mutually exclusive with --dir)")
    public var slug: String?

    @Option(
      name: .customLong("dir"),
      help: "Directory to scan recursively (mutually exclusive with --slug)")
    public var dir: String?

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    public var path: String?

    @Flag(name: .customLong("write"), help: "Apply changes (default dry run)")
    public var write: Bool = false

    public enum BacklogSort: String, ExpressibleByArgument, CaseIterable { case none, title, id }

    @Option(
      name: .customLong("sort-backlog"),
      help:
        "Agenda backlog ordering: \(BacklogSort.allCases.map{$0.rawValue}.joined(separator: ", ")) (agenda only)"
    )
    public var sortBacklog: BacklogSort = .none

    public mutating func run() async throws {
      let fm = FileManager.default
      let cwd = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      try ToolUsePolicy.guardAllowed(.agencyLogWrite, under: cwd)
      let hasSlug = (slug?.isEmpty == false)
      let hasDir = (dir?.isEmpty == false)
      guard hasSlug != hasDir else {
        throw ValidationError("Provide either --slug or --dir (exactly one)")
      }
      switch kind {
      case .agency:
        if hasSlug, let s = slug {
          let res = try AgencySortCore.apply(startingAt: cwd, slug: s, write: write)
          print(
            "[triads normalize] agency: \(res.changed ? (write ? "sorted+saved" : "would sort") : "already sorted"): \(res.path.path)"
          )
          return
        }
        let dirURL = URL(fileURLWithPath: dir!)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue else {
          throw ValidationError("--dir must point to an existing directory: \(dirURL.path)")
        }
        let skipNames: Set<String> = [
          ".git", ".build", "DerivedData", "node_modules", ".generated",
        ]
        var total = 0
        var changed = 0
        if let it = fm.enumerator(
          at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [], errorHandler: nil)
        {
          while let obj = it.nextObject() {
            guard let url = obj as? URL else { continue }
            let last = url.lastPathComponent
            if let vals = try? url.resourceValues(forKeys: [.isDirectoryKey]),
              vals.isDirectory == true
            {
              if skipNames.contains(last) {
                it.skipDescendants()
                continue
              }
              continue
            }
            guard last.hasSuffix(".agency.triad.json") else { continue }
            total += 1
            let did = try AgencySortCore.applyFile(url: url, write: write)
            if did { changed += 1 }
            print(
              "[triads normalize] agency: \(did ? (write ? "sorted+saved" : "would sort") : "already sorted"): \(url.path)"
            )
          }
        }
        print(
          "[triads normalize] agency scan complete — files: \(total); changed: \(changed)\(write ? " (saved)" : " (dry run)")"
        )
      case .agenda:
        if hasSlug, let s = slug {
          let res = try AgendaNormalizeCore.apply(
            startingAt: cwd, slug: s, write: write, backlogSort: map(sortBacklog))
          print(
            "[triads normalize] agenda: \(res.changed ? (write ? "sorted+saved" : "would sort") : "already sorted"): \(res.path.path)"
          )
          return
        }
        let dirURL = URL(fileURLWithPath: dir!)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue else {
          throw ValidationError("--dir must point to an existing directory: \(dirURL.path)")
        }
        let skipNames: Set<String> = [
          ".git", ".build", "DerivedData", "node_modules", ".generated",
        ]
        var total = 0
        var changed = 0
        if let it = fm.enumerator(
          at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [], errorHandler: nil)
        {
          while let obj = it.nextObject() {
            guard let url = obj as? URL else { continue }
            let last = url.lastPathComponent
            if let vals = try? url.resourceValues(forKeys: [.isDirectoryKey]),
              vals.isDirectory == true
            {
              if skipNames.contains(last) {
                it.skipDescendants()
                continue
              }
              continue
            }
            guard last.hasSuffix(".agenda.triad.json") else { continue }
            total += 1
            let did = try AgendaNormalizeCore.applyFile(
              url: url, write: write, backlogSort: map(sortBacklog))
            if did { changed += 1 }
            print(
              "[triads normalize] agenda: \(did ? (write ? "sorted+saved" : "would sort") : "already sorted"): \(url.path)"
            )
          }
        }
        print(
          "[triads normalize] agenda scan complete — files: \(total); changed: \(changed)\(write ? " (saved)" : " (dry run)")"
        )
      case .agent:
        if hasSlug, let s = slug {
          let res = try AgentNormalizeCore.apply(startingAt: cwd, slug: s, write: write)
          let status =
            res.changed ? (write ? "formatted+saved" : "would format") : "already formatted"
          print("[triads normalize] agent: \(status): \(res.path.path)")
          return
        }
        let dirURL = URL(fileURLWithPath: dir!)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue else {
          throw ValidationError("--dir must point to an existing directory: \(dirURL.path)")
        }
        let skipNames: Set<String> = [
          ".git", ".build", "DerivedData", "node_modules", ".generated",
        ]
        var total = 0
        var changed = 0
        if let it = fm.enumerator(
          at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [], errorHandler: nil)
        {
          while let obj = it.nextObject() {
            guard let url = obj as? URL else { continue }
            let last = url.lastPathComponent
            if let vals = try? url.resourceValues(forKeys: [.isDirectoryKey]),
              vals.isDirectory == true
            {
              if skipNames.contains(last) {
                it.skipDescendants()
                continue
              }
              continue
            }
            guard last.hasSuffix(".agent.triad.json") else { continue }
            total += 1
            let did = try AgentNormalizeCore.applyFile(url: url, write: write)
            if did { changed += 1 }
            let status = did ? (write ? "formatted+saved" : "would format") : "already formatted"
            print("[triads normalize] agent: \(status): \(url.path)")
          }
        }
        print(
          "[triads normalize] agent scan complete — files: \(total); changed: \(changed)\(write ? " (saved)" : " (dry run)")"
        )
      }
    }

    private func map(_ opt: BacklogSort) -> AgendaNormalizeCore.BacklogSortOption {
      switch opt {
      case .none: return .none
      case .title: return .title
      case .id: return .id
      }
    }
  }
}

extension TriadsCommandGroup {
  public struct Render: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "render", abstract: "Render triads to Markdown mirrors")
    }

    public init() {}

    public enum Kind: String, ExpressibleByArgument, CaseIterable { case agenda, agency, agent }

    @Option(
      name: .customLong("kind"),
      help: "Triad kind: \(Kind.allCases.map { $0.rawValue }.joined(separator: ", "))")
    public var kind: Kind = .agenda

    @Option(name: .customLong("slug"), help: "Agent slug")
    public var slug: String

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    public var path: String?

    @Flag(name: [.customShort("w"), .long], help: "Write file next to JSON under .generated/")
    public var write: Bool = false

    public func run() throws {
      switch kind {
      case .agenda:
        try renderAgenda()
      case .agency:
        try renderAgency()
      case .agent:
        try renderAgent()
      }
    }

    private func renderAgenda() throws {
      let contextDir = try resolveAgentDir()
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: contextDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      guard let agendaURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agenda.triad.json") })
      else {
        throw ValidationError("Missing *.agenda.triad.json in \(contextDir.path)")
      }
      let (slugOutput, renderedMarkdown) = try MirrorRenderer.agendaMarkdown(from: agendaURL)
      try writeOrPrint(
        renderedMarkdown, slug: slugOutput, suffix: "agenda.triad.md", sourceURL: agendaURL)
    }

    private func renderAgency() throws {
      let contextDir = try resolveAgentDir()
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: contextDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      guard let agencyURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agency.triad.json") })
      else {
        throw ValidationError("Missing *.agency.triad.json in \(contextDir.path)")
      }
      let (slugOutput, renderedMarkdown) = try MirrorRenderer.agencyMarkdown(from: agencyURL)
      try writeOrPrint(
        renderedMarkdown, slug: slugOutput, suffix: "agency.triad.md", sourceURL: agencyURL)
    }

    private func renderAgent() throws {
      let contextDir = try resolveAgentDir()
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: contextDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      guard let agentURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agent.triad.json") })
      else {
        throw ValidationError("Missing *.agent.triad.json in \(contextDir.path)")
      }
      let (slugOutput, renderedMarkdown) = try MirrorRenderer.agentMarkdown(from: agentURL)
      try writeOrPrint(
        renderedMarkdown, slug: slugOutput, suffix: "agent.triad.md", sourceURL: agentURL)
    }

    private func resolveAgentDir() throws -> URL {
      let rootURL = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let contexts = LineageResolver.findAgentDirs(for: slug, under: rootURL)
      guard let context = contexts.last else {
        throw ValidationError("No agent directory for slug=\(slug) found in lineage")
      }
      return context.dir
    }

    private func writeOrPrint(
      _ renderedMarkdown: String,
      slug: String,
      suffix: String,
      sourceURL: URL
    ) throws {
      if write {
        let outputDirectory = sourceURL.deletingLastPathComponent().appendingPathComponent(
          ".generated", isDirectory: true)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let outputURL = outputDirectory.appendingPathComponent("\(slug).\(suffix)")
        try renderedMarkdown.write(to: outputURL, atomically: true, encoding: .utf8)
        print(outputURL.path)
      } else {
        print(renderedMarkdown)
      }
    }
  }
}

extension TriadsCommandGroup {
  public struct Aggregate: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "aggregate", abstract: "Aggregate agenda triads across agents")
    }

    public init() {}

    public enum Kind: String, ExpressibleByArgument, CaseIterable { case agenda }

    @Option(
      name: .customLong("kind"),
      help: "Triad kind: \(Kind.allCases.map { $0.rawValue }.joined(separator: ", "))")
    public var kind: Kind = .agenda

    @Option(name: .long, help: "Root directory to scan (defaults to CWD)")
    public var root: String?

    @Option(name: .long, help: "Output format: json or md")
    public var format: String = "json"

    @Option(name: .long, help: "Calendar view: day|week|month|all")
    public var calendar: String?

    @Flag(name: .long, help: "Only include current (Next) items")
    public var currentOnly: Bool = false

    @Flag(name: .long, help: "Only include backlog items")
    public var backlogOnly: Bool = false

    @Flag(name: .long, help: "Include only agendas with status=active (default: false)")
    public var activeOnly: Bool = false

    public func run() throws {
      switch kind {
      case .agenda:
        try aggregateAgenda()
      }
    }

    private func aggregateAgenda() throws {
      let cwd = FileManager.default.currentDirectoryPath
      let base = URL(fileURLWithPath: root ?? cwd)
      let agentsRoot = base.appendingPathComponent(".clia/agents")
      let fileManager = FileManager.default
      guard
        let enumerator = fileManager.enumerator(
          at: agentsRoot, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )
      else {
        throw ValidationError("Could not enumerate \(agentsRoot.path)")
      }

      var results: [[String: Any]] = []
      let calMode = calendar?.lowercased()
      let now = Date()
      let iso = ISO8601DateFormatter()
      func dueInDays(_ due: String?, within days: Int) -> Bool {
        guard let s = due, let d = iso.date(from: s) else { return false }
        let interval = d.timeIntervalSince(now)
        return interval >= 0 && interval <= Double(days) * 86400.0
      }
      for case let url as URL in enumerator {
        if url.lastPathComponent.hasSuffix(".agenda.triad.json") == false { continue }
        guard let data = try? Data(contentsOf: url) else { continue }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) else { continue }
        guard let doc = obj as? [String: Any] else { continue }

        let slug =
          (doc["slug"] as? String) ?? ((doc["agent"] as? [String: Any])?["role"] as? String) ?? ""
        let title = (doc["title"] as? String) ?? slug
        let status = (doc["status"] as? String) ?? ""
        if activeOnly && status.lowercased() != "active" { continue }

        // current = sections with slug == "next" -> items: [String]
        var current: [String] = []
        if let sections = doc["sections"] as? [[String: Any]] {
          if let next = sections.first(where: { ($0["slug"] as? String) == "next" }) {
            if let items = next["items"] as? [String] {
              current = items
            }
          }
        }

        // backlog could be [String] or [Object]
        var backlog: [[String: Any]] = []
        if let bl = doc["backlog"] as? [Any] {
          for item in bl {
            if let s = item as? String {
              backlog.append(["title": s])
            } else if let d = item as? [String: Any] {
              var entry: [String: Any] = [:]
              if let t = d["title"] as? String { entry["title"] = t }
              if let s = d["slug"] as? String { entry["slug"] = s }
              if let notes = d["notes"] as? [String] { entry["notes"] = notes }
              if let links = d["links"] as? [[String: Any]] { entry["links"] = links }
              backlog.append(entry)
            }
          }
        }

        var agentBlock: [String: Any] = [
          "agent": slug,
          "title": title,
          "status": status,
          "path": url.path,
        ]
        if let cal = calMode {
          // Daily: sections[next] + horizon h0-daily/title=Daily
          if cal == "day" || cal == "all" {
            var dayItems: [String] = []
            dayItems.append(contentsOf: current)
            if let horizons = doc["horizons"] as? [[String: Any]] {
              for h in horizons {
                let slug = (h["slug"] as? String) ?? ""
                let title = (h["title"] as? String) ?? ""
                if slug.lowercased() == "h0-daily"
                  || title.localizedCaseInsensitiveContains("daily")
                {
                  if let items = h["items"] as? [String] { dayItems.append(contentsOf: items) }
                }
              }
            }
            agentBlock["day"] = dayItems
          }
          // Weekly: horizon h1-weekly + milestones due <= 7d
          if cal == "week" || cal == "all" {
            var weekItems: [String] = []
            if let horizons = doc["horizons"] as? [[String: Any]] {
              for h in horizons {
                let slug = (h["slug"] as? String) ?? ""
                let title = (h["title"] as? String) ?? ""
                if slug.lowercased() == "h1-weekly"
                  || title.localizedCaseInsensitiveContains("weekly")
                {
                  if let items = h["items"] as? [String] { weekItems.append(contentsOf: items) }
                }
              }
            }
            var dueSoon: [[String: Any]] = []
            if let mArr = doc["milestones"] as? [[String: Any]] {
              for m in mArr {
                let status = (m["status"] as? String)?.lowercased()
                if status == "done" { continue }
                let due = m["due"] as? String
                if dueInDays(due, within: 7) {
                  var entry: [String: Any] = [:]
                  entry["title"] = (m["title"] as? String) ?? ""
                  if let s = m["slug"] as? String { entry["slug"] = s }
                  if let due = due { entry["due"] = due }
                  dueSoon.append(entry)
                }
              }
            }
            agentBlock["week"] = weekItems
            agentBlock["weekMilestones"] = dueSoon
          }
          // Monthly: horizon h2-monthly/h2-quarter + milestones due <= 30d
          if cal == "month" || cal == "all" {
            var monthItems: [String] = []
            if let horizons = doc["horizons"] as? [[String: Any]] {
              for h in horizons {
                let slug = (h["slug"] as? String) ?? ""
                let title = (h["title"] as? String) ?? ""
                let ok =
                  slug.lowercased() == "h2-monthly" || slug.lowercased() == "h2-quarter"
                  || title.localizedCaseInsensitiveContains("monthly")
                  || title.localizedCaseInsensitiveContains("quarter")
                if ok, let items = h["items"] as? [String] { monthItems.append(contentsOf: items) }
              }
            }
            var dueSoon: [[String: Any]] = []
            if let mArr = doc["milestones"] as? [[String: Any]] {
              for m in mArr {
                let status = (m["status"] as? String)?.lowercased()
                if status == "done" { continue }
                let due = m["due"] as? String
                if dueInDays(due, within: 30) {
                  var entry: [String: Any] = [:]
                  entry["title"] = (m["title"] as? String) ?? ""
                  if let s = m["slug"] as? String { entry["slug"] = s }
                  if let due = due { entry["due"] = due }
                  dueSoon.append(entry)
                }
              }
            }
            agentBlock["month"] = monthItems
            agentBlock["monthMilestones"] = dueSoon
          }
        } else {
          if !currentOnly { agentBlock["backlog"] = backlog }
          if !backlogOnly { agentBlock["current"] = current }
        }
        results.append(agentBlock)
      }

      // Sort by agent slug for stability
      results.sort { (a, b) in
        let sa = (a["agent"] as? String) ?? ""
        let sb = (b["agent"] as? String) ?? ""
        return sa.localizedCaseInsensitiveCompare(sb) == .orderedAscending
      }

      if format.lowercased() == "md" {
        if calMode != nil {
          printMarkdownCalendar(results, mode: calMode!)
        } else {
          printMarkdown(results)
        }
      } else {
        try printJSON(results, calendarMode: calMode)
      }
    }

    private func printJSON(_ results: [[String: Any]], calendarMode: String?) throws {
      if let mode = calendarMode {
        var out: [String: Any] = [:]
        func agentSummary(_ a: [String: Any]) -> [String: Any] {
          var m: [String: Any] = [:]
          m["agent"] = a["agent"] ?? ""
          m["title"] = a["title"] ?? ""
          m["status"] = a["status"] ?? ""
          m["path"] = a["path"] ?? ""
          return m
        }
        if mode == "day" || mode == "all" {
          var dayArr: [[String: Any]] = []
          for a in results {
            if let items = a["day"] as? [String], !items.isEmpty {
              var obj = agentSummary(a)
              obj["items"] = items
              dayArr.append(obj)
            }
          }
          out["day"] = dayArr
        }
        if mode == "week" || mode == "all" {
          var weekArr: [[String: Any]] = []
          for a in results {
            let items = (a["week"] as? [String]) ?? []
            let ms = (a["weekMilestones"] as? [[String: Any]]) ?? []
            if !items.isEmpty || !ms.isEmpty {
              var obj = agentSummary(a)
              if !items.isEmpty { obj["items"] = items }
              if !ms.isEmpty { obj["milestones"] = ms }
              weekArr.append(obj)
            }
          }
          out["week"] = weekArr
        }
        if mode == "month" || mode == "all" {
          var monthArr: [[String: Any]] = []
          for a in results {
            let items = (a["month"] as? [String]) ?? []
            let ms = (a["monthMilestones"] as? [[String: Any]]) ?? []
            if !items.isEmpty || !ms.isEmpty {
              var obj = agentSummary(a)
              if !items.isEmpty { obj["items"] = items }
              if !ms.isEmpty { obj["milestones"] = ms }
              monthArr.append(obj)
            }
          }
          out["month"] = monthArr
        }
        let data = try JSONSerialization.data(
          withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        let out: [String: Any] = ["agents": results]
        let data = try JSONSerialization.data(
          withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
        if let s = String(data: data, encoding: .utf8) { print(s) }
      }
    }

    private func printMarkdown(_ results: [[String: Any]]) {
      for agent in results {
        let name = (agent["agent"] as? String) ?? ""
        let title = (agent["title"] as? String) ?? name
        let status = (agent["status"] as? String) ?? ""
        print("## \(title) (\(name)) — \(status)")
        if let current = agent["current"] as? [String], !current.isEmpty {
          print("- Current (Next):")
          for i in current { print("  - \(i)") }
        }
        if let backlog = agent["backlog"] as? [[String: Any]], !backlog.isEmpty {
          print("- Backlog:")
          for it in backlog {
            let t = (it["title"] as? String) ?? "(untitled)"
            let s = (it["slug"] as? String).map { " [\($0)]" } ?? ""
            print("  - \(t)\(s)")
          }
        }
        print("")
      }
    }

    private func printMarkdownCalendar(_ results: [[String: Any]], mode: String) {
      for agent in results {
        let name = (agent["agent"] as? String) ?? ""
        let title = (agent["title"] as? String) ?? name
        let status = (agent["status"] as? String) ?? ""
        print("## \(title) (\(name)) — \(status)")
        if mode == "day" || mode == "all" {
          if let day = agent["day"] as? [String], !day.isEmpty {
            print("- Today:")
            for i in day { print("  - \(i)") }
          }
        }
        if mode == "week" || mode == "all" {
          if let week = agent["week"] as? [String], !week.isEmpty {
            print("- This week:")
            for i in week { print("  - \(i)") }
          }
          if let ms = agent["weekMilestones"] as? [[String: Any]], !ms.isEmpty {
            print("  - Milestones due (≤7d):")
            for m in ms {
              let t = (m["title"] as? String) ?? "(untitled)"
              let d = (m["due"] as? String) ?? ""
              print("    - \(t) \(d.isEmpty ? "" : "(due: \(d))")")
            }
          }
        }
        if mode == "month" || mode == "all" {
          if let month = agent["month"] as? [String], !month.isEmpty {
            print("- This month:")
            for i in month { print("  - \(i)") }
          }
          if let ms = agent["monthMilestones"] as? [[String: Any]], !ms.isEmpty {
            print("  - Milestones due (≤30d):")
            for m in ms {
              let t = (m["title"] as? String) ?? "(untitled)"
              let d = (m["due"] as? String) ?? ""
              print("    - \(t) \(d.isEmpty ? "" : "(due: \(d))")")
            }
          }
        }
        print("")
      }
    }
  }
}
