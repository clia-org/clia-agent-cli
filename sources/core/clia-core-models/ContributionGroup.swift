import Foundation

/// A grouped set of evidenced contributions by a single actor.
///
/// Preferred shape for Agency entries: one group per actor (agent slug) with a
/// list of contribution items, each carrying its own evidence.
public struct ContributionGroup: Codable, Sendable {
  public var by: String
  public var types: [ContributionItem]

  public init(by: String, types: [ContributionItem]) {
    self.by = by
    self.types = types
  }
}

extension ContributionGroup {
  /// Aggregates weights by type across the group's items and returns normalized shares.
  public func normalizedSharesByType() -> [String: Double] {
    var map: [String: Double] = [:]
    for item in types { map[item.type, default: 0] += item.weight }
    let denom = map.values.reduce(0.0, +)
    guard denom > 0 else { return [:] }
    return map.mapValues { $0 / denom }
  }
}
