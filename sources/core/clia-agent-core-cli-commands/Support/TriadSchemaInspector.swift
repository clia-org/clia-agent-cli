import Foundation

public enum TriadSchemaKind: CaseIterable {
  case core
  case agent
  case agency
  case agenda

  fileprivate var schema: TriadSchema {
    switch self {
    case .core: return .core
    case .agent: return .agent
    case .agency: return .agency
    case .agenda: return .agenda
    }
  }
}

public enum TriadSchemaSource: Equatable {
  case bundle
  case override(URL)
}

public struct TriadSchemaInfo {
  public var allowedSchemaVersions: Set<String>
  public var source: TriadSchemaSource

  public init(allowedSchemaVersions: Set<String>, source: TriadSchemaSource) {
    self.allowedSchemaVersions = allowedSchemaVersions
    self.source = source
  }
}

public enum TriadSchemaInspector {
  public static func info(for kind: TriadSchemaKind, root: URL) throws -> TriadSchemaInfo {
    let resolved = try TriadSchemaLoader.resolve(schema: kind.schema, root: root)
    let data = try Data(contentsOf: resolved.url)
    let allowedVersions = parseAllowedSchemaVersions(from: data)
    let source: TriadSchemaSource = resolved.isOverride ? .override(resolved.url) : .bundle
    return TriadSchemaInfo(allowedSchemaVersions: allowedVersions, source: source)
  }

  private static func parseAllowedSchemaVersions(from data: Data) -> Set<String> {
    guard
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let properties = object["properties"] as? [String: Any],
      let schemaVersion = properties["schemaVersion"] as? [String: Any]
    else {
      return []
    }
    if let constValue = schemaVersion["const"] as? String {
      return [constValue]
    }
    if let enumValues = schemaVersion["enum"] as? [String] {
      return Set(enumValues)
    }
    return []
  }
}

extension TriadSchemaKind {
  public var displayName: String {
    switch self {
    case .core: return "core"
    case .agent: return "agent"
    case .agency: return "agency"
    case .agenda: return "agenda"
    }
  }
}
