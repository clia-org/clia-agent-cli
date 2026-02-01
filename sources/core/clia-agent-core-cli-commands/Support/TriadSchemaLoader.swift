import Foundation

enum TriadSchema: CaseIterable {
  case core
  case agent
  case agency
  case agenda

  var fileName: String {
    switch self {
    case .core: return "triads.core"
    case .agent: return "triads.agent.schema"
    case .agency: return "triads.agency.schema"
    case .agenda: return "triads.agenda.schema"
    }
  }

  var filePathComponent: String { fileName + ".json" }
}

enum TriadSchemaLoader {
  struct ResolvedSchema {
    var url: URL
    var isOverride: Bool
  }

  static func resolve(schema: TriadSchema, root: URL) throws -> ResolvedSchema {
    let custom = root.appendingPathComponent(
      ".clia/schemas/triads/\(schema.filePathComponent)"
    )
    guard FileManager.default.fileExists(atPath: custom.path) else {
      throw CocoaError(
        .fileNoSuchFile,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Triad schema not found at \(custom.path). Expected .clia/schemas/triads under workspace root."
        ]
      )
    }
    return ResolvedSchema(url: custom, isOverride: true)
  }

  static func load(schema: TriadSchema, root: URL) throws -> Data {
    let resolved = try resolve(schema: schema, root: root)
    return try Data(contentsOf: resolved.url)
  }
}
