import ArgumentParser
import CLIACoreModels
import Foundation

public struct WorkspaceValidateCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "workspace-validate",
      abstract:
        "Validate .clia/workspace.clia.json against 0.4.0 schema (presence + basic shape)")
  }

  public init() {}

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  public enum Format: String, ExpressibleByArgument, CaseIterable { case text, json }
  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map{ $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  public func run() throws {
    let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    do {
      let cfg = try WorkspaceConfig.load(under: root)
      switch format {
      case .text:
        print("workspace.clia.json \(cfg.schemaVersion) — OK")
      case .json:
        struct Payload: Codable {
          var ok: Bool
          var schemaVersion: String
        }
        let payload = Payload(ok: true, schemaVersion: cfg.schemaVersion)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(decoding: try enc.encode(payload), as: UTF8.self))
      }
    } catch {
      switch format {
      case .text:
        fputs("workspace.clia.json invalid: \(error.localizedDescription)\n", stderr)
      case .json:
        struct Payload: Codable {
          var ok: Bool
          var error: String
        }
        let payload = Payload(ok: false, error: error.localizedDescription)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(decoding: try enc.encode(payload), as: UTF8.self))
      }
      throw ExitCode.failure
    }
  }
}
