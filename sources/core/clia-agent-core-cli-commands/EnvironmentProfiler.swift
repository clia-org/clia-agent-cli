import CLIACore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

// Lightweight, shared renderer for environment directives so other commands (Ask/Reload)
// can reuse text/JSON snippets without depending on a specific CLI command.
public enum DirectivesProfiler {
  public struct Profile: Codable {
    public struct Directive: Codable {
      public var tag: String
      public var capability: String
      public var cli: String?
      public var checklist: [ChecklistItem]
    }

    public struct Sources: Codable {
      public var workspacePath: String
    }

    public var slug: String
    public var title: String
    public var mission: String?
    public var guardrails: [String]
    public var directives: [Directive]
    public var sources: Sources
    public var contextChain: [ContextEntry]?
  }

  private struct DirectiveItem {
    var tag: String
    var capability: String
    var cli: String?
    var checklist: [ChecklistItem]
  }

  public static func profile(
    slug: String, root: URL, rootChain: Bool = false
  ) throws -> Profile {
    var merged = Merger.mergeAgent(slug: slug, under: root)
    if rootChain {
      let items = LineageResolver.findAgentDirs(for: slug, under: root)
      merged.contextChain = items.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
    }

    let cfg = try WorkspaceConfig.load(under: root)
    let directivesMap = cfg.directives ?? [:]
    let orderedKeys = ["wu", "wc", "wd", "patch", "sync", "roster"]
    let directives: [DirectiveItem] = orderedKeys.compactMap { key in
      guard let directive = directivesMap[key] else { return nil }
      return DirectiveItem(
        tag: "!\(key)", capability: directive.capability, cli: directive.cli,
        checklist: directive.checklist)
    }

    return Profile(
      slug: slug,
      title: merged.title,
      mission: merged.purpose,
      guardrails: merged.guardrails,
      directives: directives.map {
        Profile.Directive(
          tag: $0.tag, capability: $0.capability, cli: $0.cli, checklist: $0.checklist)
      },
      sources: .init(workspacePath: ".clia/workspace.clia.json"),
      contextChain: merged.contextChain
    )
  }

  public static func render(
    slug: String, root: URL, format: String = "json", rootChain: Bool = false
  ) throws -> String {
    let profile = try profile(slug: slug, root: root, rootChain: rootChain)

    switch format.lowercased() {
    case "json":
      let enc = JSON.Formatting.humanEncoder
      return String(decoding: try enc.encode(profile), as: UTF8.self)
    case "text":
      var out: [String] = []
      out.append("agent: \(profile.title) [\(profile.slug)]")
      if let mission = profile.mission {
        out.append("mission: \(mission.replacingOccurrences(of: "\n", with: " "))")
      }
      out.append("directives:")
      for directive in profile.directives {
        out.append("- \(directive.tag) → \(directive.capability)")
        if let cli = directive.cli { out.append("  cli: \(cli)") }
        for item in directive.checklist { out.append("  • [\(item.level.rawValue)] \(item.text)") }
      }
      return out.joined(separator: "\n")
    case "md":
      var out = "# Environment Directives — \(profile.title) (\(profile.slug))\n\n"
      out += "**Directives**:\n"
      for directive in profile.directives {
        let cliSuffix = directive.cli.flatMap { " — `\($0)`" } ?? ""
        out += "- \(directive.tag) → \(directive.capability)\(cliSuffix)\n"
        for item in directive.checklist { out += "  - [\(item.level.rawValue)] \(item.text)\n" }
      }
      return out
    default:
      return try render(slug: slug, root: root, format: "json", rootChain: rootChain)
    }
  }
}
