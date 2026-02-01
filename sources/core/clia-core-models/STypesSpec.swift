import Foundation

// MARK: - S‑Types Collaboration Spec (Swift model)

public enum STypesRelation: String, Codable, CaseIterable, Sendable {
  case synergizes_with
  case stabilizes_with
  case strains_with
}

public struct STypesMultipliers: Codable, Sendable {
  public var synergizes_with: Double
  public var stabilizes_with: Double
  public var strains_with: Double
  public var neutral: Double
  public init(
    synergizes_with: Double = 2.0,
    stabilizes_with: Double = 1.5,
    strains_with: Double = 0.7,
    neutral: Double = 1.0
  ) {
    self.synergizes_with = synergizes_with
    self.stabilizes_with = stabilizes_with
    self.strains_with = strains_with
    self.neutral = neutral
  }
  public func value(for relation: STypesRelation?) -> Double {
    guard let r = relation else { return neutral }
    switch r {
    case .synergizes_with: return synergizes_with
    case .stabilizes_with: return stabilizes_with
    case .strains_with: return strains_with
    }
  }
}

public struct STypesRoleRelations: Codable, Sendable {
  public var synergizes_with: [String]?
  public var stabilizes_with: [String]?
  public var strains_with: [String]?
  public init(
    synergizes_with: [String]? = nil,
    stabilizes_with: [String]? = nil,
    strains_with: [String]? = nil
  ) {
    self.synergizes_with = synergizes_with
    self.stabilizes_with = stabilizes_with
    self.strains_with = strains_with
  }

  public func relation(to other: String) -> STypesRelation? {
    if (synergizes_with ?? []).contains(other) { return .synergizes_with }
    if (stabilizes_with ?? []).contains(other) { return .stabilizes_with }
    if (strains_with ?? []).contains(other) { return .strains_with }
    return nil
  }
}

public struct STypesSpec: Codable, Sendable {
  public var version: Int
  public var schema: [STypesRelation]
  public var multipliers: STypesMultipliers
  public var types: [String: STypesRoleRelations]

  public init(
    version: Int,
    schema: [STypesRelation],
    multipliers: STypesMultipliers,
    types: [String: STypesRoleRelations]
  ) {
    self.version = version
    self.schema = schema
    self.multipliers = multipliers
    self.types = types
  }

  // MARK: - Convenience

  public var roles: [String] { Array(types.keys).sorted() }

  /// Returns the strongest relation from `a` to `b` when present, otherwise nil.
  public func relation(from a: String, to b: String) -> STypesRelation? {
    guard let rel = types[a] else { return nil }
    return rel.relation(to: b)
  }

  /// Returns the numeric multiplier for (a,b) or neutral when none exists.
  public func multiplier(from a: String, to b: String) -> Double {
    let rel = relation(from: a, to: b)
    return multipliers.value(for: rel)
  }

  /// Roles referenced inside relation lists that are not defined as top-level types.
  public func unknownRoleReferences() -> [String] {
    let defined = Set(types.keys)
    var referenced: Set<String> = []
    for (_, rel) in types {
      for r in rel.synergizes_with ?? [] { referenced.insert(r) }
      for r in rel.stabilizes_with ?? [] { referenced.insert(r) }
      for r in rel.strains_with ?? [] { referenced.insert(r) }
    }
    return Array(referenced.subtracting(defined)).sorted()
  }

  // MARK: - Loader

  public static func load(from url: URL) throws -> STypesSpec {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(STypesSpec.self, from: data)
  }
}
