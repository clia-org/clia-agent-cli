import Foundation

public enum WorkspaceSchemaVersion {
  public static let current = "0.4.0"
}

public struct WorkspaceConfig: Decodable {
  public var schemaVersion: String
  public var operatorInfo: OperatorInfo?
  public var terminalogy: Terminalogy?
  public var header: ResponseHeader?
  public var org: Org?
  public var realms: [String: Realm]?
  public var git: Git?
  public var sharing: Sharing?
  public var preferences: Preferences?
  public var policy: Policy?
  public var directives: [String: Directive]?

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case operatorInfo = "operator"
    case terminalogy, header, org, realms, git, sharing, preferences, policy, directives
  }

  public struct OperatorInfo: Codable {
    public var id: String?
    public var workspace: String?
    public var org: String?
    public var role: String?
    public var permissions: [String]?
  }
  public struct Terminalogy: Codable {
    public var ref: String?
    public var override: Override?
    public struct Override: Codable {
      public var naming: Naming?
      public var theme: Theme?
    }
    public struct Naming: Codable {
      public var repo: String?
      public var ghost: String?
      public var agent: String?
    }
    public struct Theme: Codable {
      public var primary: String?
      public var secondary: String?
      public var muted: String?
      public var accent: String?
      public var danger: String?
      public var success: String?
    }
  }
  public struct Org: Codable {
    public var id: String?
    public var visibility: String?
    public var repos: [Repo]?
    public struct Repo: Codable {
      public var name: String?
      public var alias: String?
      public var realms: [String]?
      public var ghosts: [Ghost]?
    }
    public struct Ghost: Codable {
      public var persona: String?
      public var stack: String?
      public var traits: [String]?
    }
  }
  public struct Realm: Codable {
    public var label: String?
    public var targets: [Target]?
    public var `default`: Bool?
  }
  public struct Target: Codable {
    public let values: [String: String]
    public init(from decoder: Decoder) throws {
      self.values = try decoder.singleValueContainer().decode([String: String].self)
    }
    public func encode(to encoder: Encoder) throws {
      var c = encoder.singleValueContainer()
      try c.encode(values)
    }
  }
  public struct Git: Codable {
    public var visibility: String?
    public var pushAllowed: Bool?
  }
  public struct Sharing: Codable {
    public var visibility: String?
    public var publishAllowed: Bool?
  }
  public struct Preferences: Codable {
    public var emojiPosture: String?
    public var output: Output?
    public var useTerminalogyTheme: Bool?
    public struct Output: Codable {
      public var pagination: String?
      public var width: Int?
    }
  }
  public struct Policy: Codable {
    public var guardrails: [String]?
    public var capabilities: [String]?
  }
  public struct Directive: Codable {
    public var capability: String
    public var cli: String
    public var inputs: [String: Bool]?
    public var checklist: [ChecklistItem]
    public var effects: [String]?
    public var telemetry: Telemetry?
    public struct Telemetry: Codable { public var emit: [String]? }
  }

  public static func load(under root: URL) throws -> WorkspaceConfig {
    // Canonical (v4): .clia/workspace.clia.json
    let fm = FileManager.default
    let url = root.appendingPathComponent(".clia/workspace.clia.json")
    guard fm.fileExists(atPath: url.path) else {
      throw NSError(
        domain: "Workspace", code: 404,
        userInfo: [
          NSLocalizedDescriptionKey: ".clia/workspace.clia.json not found"
        ])
    }
    let data = try Data(contentsOf: url)
    let cfg = try JSONDecoder().decode(WorkspaceConfig.self, from: data)
    guard cfg.schemaVersion == WorkspaceSchemaVersion.current else {
      throw NSError(
        domain: "Workspace", code: 422,
        userInfo: [
          NSLocalizedDescriptionKey:
            "workspace.clia.json schemaVersion must be \(WorkspaceSchemaVersion.current)"
        ])
    }
    return cfg
  }
}
