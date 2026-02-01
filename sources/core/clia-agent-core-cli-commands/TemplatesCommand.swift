import ArgumentParser
import Foundation

public struct TemplatesCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "templates",
      abstract: "List bundled agent templates"
    )
  }

  public enum Format: String, ExpressibleByArgument, CaseIterable {
    case text
    case json
  }

  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))"
  )
  public var format: Format = .text

  public init() {}

  public func run() throws {
    let templates = try Self.templates()
    switch format {
    case .text:
      renderText(templates)
    case .json:
      try renderJSON(templates)
    }
  }

  // MARK: - Helpers

  struct TemplateInfo: Equatable {
    var name: String
    var files: [String]
  }

  static func templates() throws -> [TemplateInfo] {
    guard let bundleURL = Bundle.module.resourceURL else {
      return []
    }

    let fm = FileManager.default
    let candidateURLs = [
      bundleURL.appendingPathComponent("templates/index.json"),
      bundleURL.appendingPathComponent("index.json"),
    ]

    guard let indexURL = candidateURLs.first(where: { fm.fileExists(atPath: $0.path) }) else {
      return []
    }

    struct TemplateIndexEntry: Decodable {
      var name: String
      var files: [String]
    }

    let data = try Data(contentsOf: indexURL)
    let decoder = JSONDecoder()
    let entries = try decoder.decode([TemplateIndexEntry].self, from: data)

    return
      entries
      .map { TemplateInfo(name: $0.name, files: $0.files.sorted()) }
      .sorted { $0.name < $1.name }
  }

  private func renderText(_ templates: [TemplateInfo]) {
    guard !templates.isEmpty else {
      print("No bundled templates found.")
      return
    }
    for template in templates {
      print("- \(template.name)")
      for file in template.files {
        print("  • \(file)")
      }
    }
  }

  private func renderJSON(_ templates: [TemplateInfo]) throws {
    let payload: [[String: Any]] = templates.map { template in
      [
        "name": template.name,
        "files": template.files,
      ]
    }
    let data = try JSONSerialization.data(
      withJSONObject: payload,
      options: [.prettyPrinted, .sortedKeys]
    )
    guard let string = String(data: data, encoding: .utf8) else { return }
    print(string)
  }
}
