import ArgumentParser
import CLIACoreModels
import Foundation

public enum IncidentCore {
  public static func readActive(at root: URL) -> Incident? {
    let url = root.appendingPathComponent(".clia/incidents/active.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(Incident.self, from: data)
  }
}

public struct IncidentsCoreGroup: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(commandName: "incidents", abstract: "Incidents (read-only)", subcommands: [Status.self])
  }
  public init() {}
}

extension IncidentsCoreGroup {
  public struct Status: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "status", abstract: "Print current active incident banner (if any)")
    }
    public init() {}
    @Option(name: .customLong("path"), help: "Repo root (default: CWD)")
    public var path: String?
    public func run() throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      if let inc = IncidentCore.readActive(at: root) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try enc.encode(inc)
        print(String(decoding: data, as: UTF8.self))
      } else {
        print("no active incident")
      }
    }
  }
}
