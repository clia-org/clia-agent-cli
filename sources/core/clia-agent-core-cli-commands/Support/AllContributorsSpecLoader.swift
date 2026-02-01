import Foundation

struct AllContributorsSpecEntry: Codable {
  var emoji: String
  var title: String
  var description: String?
  var synonyms: [String]?
}

enum AllContributorsSpecLoader {
  private struct SpecFile: Codable {
    var types: [String: AllContributorsSpecEntry]
  }

  static func loadSpec(root: URL?) throws -> [String: AllContributorsSpecEntry] {
    if let root {
      let custom = root.appendingPathComponent(
        ".clia/specs/all-contributors-types.v1.json")
      if FileManager.default.fileExists(atPath: custom.path) {
        return try decode(url: custom)
      }
    }
    guard
      let url = Bundle.module.url(
        forResource: "all-contributors-types.v1",
        withExtension: "json"
      )
    else {
      throw CocoaError(
        .fileNoSuchFile,
        userInfo: [NSLocalizedDescriptionKey: "Embedded all-contributors spec missing"]
      )
    }
    return try decode(url: url)
  }

  private static func decode(url: URL) throws -> [String: AllContributorsSpecEntry] {
    let data = try Data(contentsOf: url)
    let spec = try JSONDecoder().decode(SpecFile.self, from: data)
    return spec.types
  }
}
