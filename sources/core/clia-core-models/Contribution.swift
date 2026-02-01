import Foundation

/// A contribution type and weight used across triads.
///
/// - type: Kebab-case S-Types identifier (for example, "code", "design").
/// - weight: Relative weight (> 0). Writers may default to 1; readers often
///           normalize sets of contributions to shares.
public struct Contribution: Codable, Sendable {
  public var type: String
  public var weight: Double

  public init(type: String, weight: Double) {
    self.type = type
    self.weight = weight
  }
}

extension Array where Element == Contribution {
  /// Normalizes this list into shares by last-wins coalescing on type then
  /// dividing by the sum of weights. Returns an empty map when the denominator is 0.
  public func normalizedShares() -> [String: Double] {
    var map: [String: Double] = [:]
    for c in self { map[c.type] = c.weight }
    let denom = map.values.reduce(0.0, +)
    guard denom > 0 else { return [:] }
    var out: [String: Double] = [:]
    for (k, v) in map { out[k] = v / denom }
    return out
  }
}
