import ArgumentParser
import CLIAIncidentCoreCommands
import CLIAIncidentResolutionCommands
import Foundation

public struct IncidentsCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "incidents",
      abstract: "Incident utilities (read/write status)",
      subcommands: [
        Status.self,
        IncidentsResolutionGroup.New.self,
        IncidentsResolutionGroup.Activate.self,
        IncidentsResolutionGroup.Clear.self,
      ]
    )
  }

  public init() {}
}

extension IncidentsCommand {
  // Print active incident status for operators/agents
  public struct Status: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "status", abstract: "Print current active incident banner (if any)")
    }
    public init() {}
    @Option(name: .customLong("path"), help: "Repo root (default: CWD)")
    public var path: String?
    public func run() throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      guard let incident = IncidentCore.readActive(at: root) else {
        print("no active incident")
        return
      }
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      let data = try encoder.encode(incident)
      print(String(decoding: data, as: UTF8.self))
    }
  }
}
