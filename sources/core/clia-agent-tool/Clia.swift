import ArgumentParser
import CLIAAgentCoreCLICommands
import CommonShellArguments
import ConsoleKitTerminal
import GoogleGenerativeAI
import Metrics
import SwiftFigletKit
import WrkstrmFoundation
import CommonLog

#if os(Linux)
@preconcurrency import Foundation
#else
import Foundation
#endif

@main
struct Clia: AsyncParsableCommand {
  static func main(_ arguments: [String]? = nil) async {
    do {
      var command = try parseAsRoot(arguments)
      defer { CliaMetrics.flush() }
      CliaMetrics.recordInvocation(commandName: commandName(for: command))
      if var asyncCommand = command as? AsyncParsableCommand {
        try await asyncCommand.run()
      } else {
        try command.run()
      }
    } catch {
      exit(withError: error)
    }
  }

  static func main() async {
    await main(nil)
  }

  static let configuration: CommandConfiguration = .init(
    commandName: "clia",
    abstract: "Interact with AI from the command line.",
    discussion: "Utilities live in CLIKit (notifications, transcript tools).",
    subcommands: [
      Ask.self,
      ChatStreaming.self,
      Doctor.self,
      Wind.self,
      Agents.self,
      Core.self,
    ],
    defaultSubcommand: Ask.self
  )

  @Flag(name: .customLong("no-banner"), help: "Suppress Figlet banner in default flow")
  var noBanner: Bool = false

  @OptionGroup var version: CommonShellVersionOptions

  mutating func run() async throws {
    let defaultArgs: [String] = noBanner ? ["--no-banner"] : []
    var ask = try Ask.parse(defaultArgs)
    try await ask.run()
  }

  private static func commandName(for command: ParsableCommand) -> String {
    let commandType = type(of: command)
    if let explicitName = commandType.configuration.commandName, !explicitName.isEmpty {
      return explicitName
    }
    return String(describing: commandType)
  }
}

// Make repo-root finder available module-wide for nested commands
func findRepoRoot(startingAt url: URL) -> URL? {
  var current = url
  let fm = FileManager.default
  while true {
    if fm.fileExists(atPath: current.appendingPathComponent("AGENCY.md").path)
      || fm.fileExists(atPath: current.appendingPathComponent("AGENTS.md").path)
    {
      return current
    }
    let parent = current.deletingLastPathComponent()
    if parent.path == current.path { return nil }
    current = parent
  }
}
