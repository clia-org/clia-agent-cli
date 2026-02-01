import Foundation

public struct STypeSpec: Codable, Equatable {
  public struct Entry: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
      case synergizesWith = "synergizes_with"
      case stabilizesWith = "stabilizes_with"
      case strainsWith = "strains_with"
    }
    var synergizesWith: [String]?
    var stabilizesWith: [String]?
    var strainsWith: [String]?
  }

  public var types: [String: Entry]
}

public enum STypeSpecLoader {
  public static func load(root: URL?) throws -> STypeSpec {
    if let root {
      let custom = root.appendingPathComponent(
        ".clia/specs/clia-collaboration-s-types.v1.json"
      )
      if FileManager.default.fileExists(atPath: custom.path) {
        return try decode(url: custom)
      }
    }
    guard
      let url = Bundle.module.url(
        forResource: "clia-collaboration-s-types.v1",
        withExtension: "json"
      )
    else {
      throw CocoaError(
        .fileNoSuchFile,
        userInfo: [
          NSLocalizedDescriptionKey: "Embedded S-Type spec missing"
        ]
      )
    }
    return try decode(url: url)
  }

  private static func decode(url: URL) throws -> STypeSpec {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(STypeSpec.self, from: data)
  }
}
