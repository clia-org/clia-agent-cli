import ArgumentParser
import CLIAAgentCore
import Foundation

public struct JournalCommand: AsyncParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "journal",
      abstract: "Append a JSON journal entry at the parent submodule root"
    )
  }

  @Option(name: .customLong("slug"), help: "Agent slug")
  public var slug: String = "codex"

  @Option(name: .customLong("path"), help: "Working directory to resolve repo root (default: CWD)")
  public var path: String?

  @Option(name: .customLong("agent-version"))
  public var agentVersion: String?

  @Option(name: .customLong("highlight"), parsing: .upToNextOption)
  public var highlights: [String] = []

  @Option(name: .customLong("focus"), parsing: .upToNextOption)
  public var focus: [String] = []

  @Option(name: .customLong("next-step"), parsing: .upToNextOption)
  public var nextSteps: [String] = []

  @Option(
    name: .customLong("dirs-touched"), parsing: .upToNextOption,
    help: "Directories touched (repeatable); stored as x-dirsTouched")
  public var dirsTouched: [String] = []

  public init() {}

  public mutating func run() async throws {
    let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    try ToolUsePolicy.guardAllowed(.journalAppend, under: cwd)
    let out = try JournalWriter.append(
      slug: slug,
      workingDirectory: cwd,
      agentVersion: agentVersion,
      highlights: highlights,
      focus: focus,
      nextSteps: nextSteps,
      signature: "auto",
      dirsTouched: dirsTouched.isEmpty ? nil : dirsTouched
    )
    print(out.path)
  }
}
