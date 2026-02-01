import ArgumentParser
import CLIAAgentCore
import Foundation

public struct RosterUpdateCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "roster-update",
      abstract: "Add or update the agent's row in AGENTS.md at the parent submodule root"
    )
  }

  @Option(name: .customLong("title")) public var title: String
  @Option(name: .customLong("slug")) public var slug: String
  @Option(name: .customLong("summary")) public var summary: String
  @Option(name: .customLong("path")) public var path: String?

  public init() {}

  public func run() throws {
    let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    try ToolUsePolicy.guardAllowed(.rosterUpdateWrite, under: cwd)
    let out = try RosterUpdater.update(startingAt: cwd, title: title, slug: slug, summary: summary)
    print(out.path)
  }
}
