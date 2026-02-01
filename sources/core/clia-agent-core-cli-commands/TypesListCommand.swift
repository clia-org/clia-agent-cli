import ArgumentParser
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct TypesListCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "types-list", abstract: "List All‑Contributors types with emoji and synonyms")
  }

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  public enum Format: String, ExpressibleByArgument, CaseIterable { case json, text, md }
  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .json

  public init() {}

  public func run() throws {
    let root = path.map { URL(fileURLWithPath: $0) }
    let spec = try AllContributorsSpecLoader.loadSpec(root: root)
    let rows = spec.keys.sorted().map { key -> [String: Any] in
      let entry = spec[key]!
      return [
        "type": key,
        "emoji": entry.emoji,
        "title": entry.title,
        "synonyms": entry.synonyms ?? [],
      ]
    }
    switch format {
    case .json:
      let data = try JSONSerialization.data(
        withJSONObject: rows, options: JSON.Formatting.humanOptions)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    case .text:
      for r in rows {
        let type = r["type"] as! String
        let emoji = r["emoji"] as! String
        let title = r["title"] as! String
        let syn = (r["synonyms"] as? [String] ?? []).joined(separator: ", ")
        print("\(emoji)  \(type) — \(title): \(syn)")
      }
    case .md:
      print("| Type | Emoji | Title | Synonyms |\n| --- | --- | --- | --- |")
      for r in rows {
        let type = r["type"] as! String
        let emoji = r["emoji"] as! String
        let title = r["title"] as! String
        let syn = (r["synonyms"] as? [String] ?? []).joined(separator: ", ")
        print("| \(type) | \(emoji) | \(title) | \(syn) |")
      }
    }
  }
}
