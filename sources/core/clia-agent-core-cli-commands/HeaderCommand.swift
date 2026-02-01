import ArgumentParser
import Foundation
import WrkstrmFoundation
import CommonLog
import WrkstrmMain

public struct HeaderCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "header",
      abstract: "Print the standard 3-line conversation header (incident-aware)"
    )
  }

  public init() {}

  @Option(name: .customLong("slug"), help: "Agent slug (default: codex)")
  public var slug: String = "codex"

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  public enum Format: String, ExpressibleByArgument, CaseIterable { case text, json }
  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  public func run() throws {
    let fm = FileManager.default
    let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
    let h = ConversationHeader.render(slug: slug, under: root)
    switch format {
    case .text:
      if let h {
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
    case .json:
      struct Payload: Codable {
        var slug: String
        var header: [String]
      }
      let headerLines: [String] =
        h.map { [$0.line1, $0.line2] + ($0.line3.map { [$0] } ?? []) } ?? []
      let payload = Payload(slug: slug, header: headerLines)
      let enc = JSON.Formatting.humanEncoder
      print(String(decoding: try enc.encode(payload), as: UTF8.self))
    }
  }
}

extension HeaderCommand {
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
