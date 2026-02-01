import Foundation

/// Captures the planned contribution mix for a backlog item or milestone.
public struct ExpectedContributions: Codable, Sendable {
  public struct Targets: Codable, Sendable {
    public var synergyMin: Double?
    public var stabilityMin: Double?

    public init(synergyMin: Double? = nil, stabilityMin: Double? = nil) {
      self.synergyMin = synergyMin
      self.stabilityMin = stabilityMin
    }
  }

  public var types: [String]
  public var targets: Targets?

  public init(types: [String], targets: Targets? = nil) {
    self.types = types
    self.targets = targets
  }
}
