import Foundation

/// A journal entry in Agency that can carry evidenced, per-actor contributions.
///
/// Preferred shape groups contributions by actor (agent slug) with required
/// per-item evidence. `contributionGroups` is encoded at the `contributions` key.
public struct AgencyEntry: Codable, Sendable {
  public var timestamp: String
  public var kind: String?
  public var title: String?
  public var summary: String?
  public var details: [String]?
  public var tags: [String]?
  public var links: [LinkRef]?
  /// Grouped contributions (preferred, required in 0.4.0 triads).
  public var contributionGroups: [ContributionGroup]
  public var extensions: [String: ExtensionValue]?

  public init(
    timestamp: String,
    kind: String? = nil,
    title: String? = nil,
    summary: String? = nil,
    details: [String]? = nil,
    tags: [String]? = nil,
    links: [LinkRef]? = nil,
    contributionGroups: [ContributionGroup],
    extensions: [String: ExtensionValue]? = nil
  ) {
    self.timestamp = timestamp
    self.kind = kind
    self.title = title
    self.summary = summary
    self.details = details
    self.tags = tags
    self.links = links
    self.contributionGroups = contributionGroups
    self.extensions = extensions
  }

  private enum CodingKeys: String, CodingKey {
    case timestamp
    case kind
    case title
    case summary
    case details
    case tags
    case links
    case contributions
    case extensions
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.timestamp = try c.decode(String.self, forKey: .timestamp)
    self.kind = try c.decodeIfPresent(String.self, forKey: .kind)
    self.title = try c.decodeIfPresent(String.self, forKey: .title)
    self.summary = try c.decodeIfPresent(String.self, forKey: .summary)
    self.details = try c.decodeIfPresent([String].self, forKey: .details)
    self.tags = try c.decodeIfPresent([String].self, forKey: .tags)
    self.links = try c.decodeIfPresent([LinkRef].self, forKey: .links)
    self.contributionGroups = try c.decode([ContributionGroup].self, forKey: .contributions)
    self.extensions = try c.decodeIfPresent([String: ExtensionValue].self, forKey: .extensions)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(timestamp, forKey: .timestamp)
    try c.encodeIfPresent(kind, forKey: .kind)
    try c.encodeIfPresent(title, forKey: .title)
    try c.encodeIfPresent(summary, forKey: .summary)
    try c.encodeIfPresent(details, forKey: .details)
    try c.encodeIfPresent(tags, forKey: .tags)
    try c.encodeIfPresent(links, forKey: .links)
    try c.encode(contributionGroups, forKey: .contributions)
    try c.encodeIfPresent(extensions, forKey: .extensions)
  }
}

extension AgencyEntry {
  /// Returns the unique list of participant slugs. Prefers `contributionGroups` when present.
  public var participantSlugs: [String] {
    return contributionGroups.map { $0.by }
  }

  /// Aggregates weights by contribution type across all groups. If no groups are present,
  /// legacy flat contributions are treated as weight 1 each.
  public func aggregatedWeightsByType() -> [String: Double] {
    var map: [String: Double] = [:]
    for g in contributionGroups {
      for item in g.types { map[item.type, default: 0] += item.weight }
    }
    return map
  }

  /// Normalized shares by type across the entry.
  public func normalizedSharesByType() -> [String: Double] {
    let map = aggregatedWeightsByType()
    let denom = map.values.reduce(0.0, +)
    guard denom > 0 else { return [:] }
    return map.mapValues { $0 / denom }
  }
}
