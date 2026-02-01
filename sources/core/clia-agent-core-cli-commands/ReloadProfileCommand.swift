import ArgumentParser
import CLIACore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import CommonLog
import WrkstrmMain

public struct ReloadProfileCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "reload-profile",
      abstract: "Reload merged agent profile, environment directives, and active incident"
    )
  }

  public init() {}

  @Option(name: .customLong("slug"), help: "Agent slug (default: codex)")
  public var slug: String = "codex"

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  public enum Format: String, ExpressibleByArgument, CaseIterable { case json, text, md }
  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  @Flag(name: .customLong("root-chain"), help: "Include lineage directories (json)")
  public var rootChain: Bool = false

  public func run() throws {
    let fm = FileManager.default
    let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
    var agent = Merger.mergeAgent(slug: slug, under: root)
    if rootChain {
      let items = LineageResolver.findAgentDirs(for: slug, under: root)
      agent.contextChain = items.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
    }
    let header = ConversationHeader.render(slug: slug, under: root)
    let envText = try DirectivesProfiler.render(
      slug: slug, root: root, format: "text", rootChain: rootChain)

    switch format {
    case .json:
      struct Payload: Codable {
        var slug: String
        var title: String
        var guardrails: [String]
        var header: [String]
        var environmentDirectivesText: String
        var contextChain: [ContextEntry]?
      }
      let payload = Payload(
        slug: slug,
        title: agent.title,
        guardrails: agent.guardrails,
        header: header.map { [$0.line1, $0.line2] + ($0.line3.map { [$0] } ?? []) } ?? [],
        environmentDirectivesText: envText,
        contextChain: agent.contextChain
      )
      let enc = JSON.Formatting.humanEncoder
      print(String(decoding: try enc.encode(payload), as: UTF8.self))
    case .text:
      if let h = header {
        print(h.line1)
        print(h.line2)
        if let l3 = h.line3 {
          if ProcessInfo.inXcodeEnvironment {
            print(l3)
          } else {
            print(Self.colorizeSeverityLine(l3))
          }
        }
      }
      print("\n-- environment directives --")
      print(envText)
    case .md:
      print("# Conversation Header\n")
      if let h = header {
        print("\(h.line1)\n\(h.line2)")
        if let l3 = h.line3 { print(l3) }
      } else {
        print("(no header configured)\n")
      }
      print("\n## Environment Directives\n")
      print(envText)
    }
  }
}

extension ReloadProfileCommand {
  static func colorizeSeverityLine(_ text: String) -> String {
    let upper = text.uppercased()
    let code: String
    if upper.contains(" S1 ") {
      code = "\u{001B}[31m"
    } else if upper.contains(" S2 ") {
      code = "\u{001B}[33m"
    } else if upper.contains(" S3 ") {
      code = "\u{001B}[36m"
    } else {
      code = "\u{001B}[35m"
    }
    return code + text + "\u{001B}[0m"
  }
}
