import Foundation

public enum STypeRelation: String {
  case synergy
  case stability
  case strain
  case neutral

  var multiplier: Double {
    switch self {
    case .synergy: return 2.0
    case .stability: return 1.5
    case .strain: return 0.7
    case .neutral: return 1.0
    }
  }
}

public struct STypeMixMetrics: Equatable {
  public var types: [String]
  public var pairCount: Int
  public var totalWeight: Double
  public var synergyMass: Double
  public var stabilityMass: Double
  public var strainMass: Double
  public var neutralMass: Double
  public var averageMultiplier: Double

  public var synergyShare: Double { totalWeight > 0 ? synergyMass / totalWeight : 0 }
  public var stabilityShare: Double { totalWeight > 0 ? stabilityMass / totalWeight : 0 }
  public var strainShare: Double { totalWeight > 0 ? strainMass / totalWeight : 0 }
}

public struct STypeRecommendation: Equatable {
  public var type: String
  public var deltaSynergyShare: Double
  public var deltaStabilityShare: Double
  public var deltaStrainShare: Double
  public var composite: Double
}

public enum STypeMixEvaluator {
  public static func evaluate(
    mix: [String: Double],
    spec: STypeSpec
  ) -> STypeMixMetrics {
    let orderedTypes = mix.keys.sorted()
    let shares = normalizedShares(mix: mix)
    var synergyMass: Double = 0
    var stabilityMass: Double = 0
    var strainMass: Double = 0
    var neutralMass: Double = 0
    var multiplierWeightedSum: Double = 0

    let typesArray = Array(mix.keys)
    let pairCount = typesArray.count > 1 ? (typesArray.count * (typesArray.count - 1)) / 2 : 0

    guard pairCount > 0 else {
      return STypeMixMetrics(
        types: orderedTypes,
        pairCount: 0,
        totalWeight: 0,
        synergyMass: 0,
        stabilityMass: 0,
        strainMass: 0,
        neutralMass: 0,
        averageMultiplier: 1
      )
    }

    var shareProductsSum: Double = 0
    for i in 0..<(typesArray.count) {
      for j in (i + 1)..<typesArray.count {
        let a = typesArray[i]
        let b = typesArray[j]
        shareProductsSum += pairShare(a: a, b: b, shares: shares)
      }
    }

    let scaling: Double
    if shareProductsSum == 0 {
      scaling = Double(pairCount)
    } else {
      scaling = Double(pairCount) / shareProductsSum
    }

    var totalWeight: Double = 0
    for i in 0..<(typesArray.count) {
      for j in (i + 1)..<typesArray.count {
        let a = typesArray[i]
        let b = typesArray[j]
        let baseShare = pairShare(a: a, b: b, shares: shares)
        let weight = baseShare * scaling
        let relation = relationBetween(a: a, b: b, spec: spec)
        switch relation {
        case .synergy: synergyMass += weight
        case .stability: stabilityMass += weight
        case .strain: strainMass += weight
        case .neutral: neutralMass += weight
        }
        multiplierWeightedSum += relation.multiplier * weight
        totalWeight += weight
      }
    }

    return STypeMixMetrics(
      types: orderedTypes,
      pairCount: pairCount,
      totalWeight: totalWeight,
      synergyMass: synergyMass,
      stabilityMass: stabilityMass,
      strainMass: strainMass,
      neutralMass: neutralMass,
      averageMultiplier: totalWeight > 0 ? multiplierWeightedSum / totalWeight : 1
    )
  }

  public static func recommendations(
    mix: [String: Double],
    spec: STypeSpec,
    top count: Int
  ) -> [STypeRecommendation] {
    guard count > 0 else { return [] }
    let baseMetrics = evaluate(mix: mix, spec: spec)
    let existing = Set(mix.keys)
    var recs: [STypeRecommendation] = []
    let baseShares = sharesTuple(baseMetrics)
    let baseComposite = composite(baseShares)
    let defaultWeight: Double = mix.isEmpty ? 1 : (mix.values.reduce(0, +) / Double(mix.count))

    for candidate in spec.types.keys where !existing.contains(candidate) {
      var newMix = mix
      newMix[candidate] = defaultWeight
      let metrics = evaluate(mix: newMix, spec: spec)
      let shares = sharesTuple(metrics)
      let recommendation = STypeRecommendation(
        type: candidate,
        deltaSynergyShare: shares.synergy - baseShares.synergy,
        deltaStabilityShare: shares.stability - baseShares.stability,
        deltaStrainShare: shares.strain - baseShares.strain,
        composite: composite(shares) - baseComposite
      )
      recs.append(recommendation)
    }

    return
      recs
      .sorted { lhs, rhs in
        if lhs.composite == rhs.composite {
          if lhs.deltaSynergyShare == rhs.deltaSynergyShare {
            return lhs.type < rhs.type
          }
          return lhs.deltaSynergyShare > rhs.deltaSynergyShare
        }
        return lhs.composite > rhs.composite
      }
      .prefix(count)
      .map { $0 }
  }

  // MARK: - Helpers

  private static func normalizedShares(mix: [String: Double]) -> [String: Double] {
    let total = mix.values.reduce(0.0, +)
    guard total > 0 else {
      let equal = 1.0 / Double(max(mix.count, 1))
      return Dictionary(uniqueKeysWithValues: mix.keys.map { ($0, equal) })
    }
    return mix.mapValues { max($0, 0) / total }
  }

  private static func pairShare(a: String, b: String, shares: [String: Double]) -> Double {
    let shareA = shares[a] ?? 0
    let shareB = shares[b] ?? 0
    if shareA == 0 && shareB == 0 { return 0 }
    return max(shareA, 0) * max(shareB, 0)
  }

  private static func relationBetween(a: String, b: String, spec: STypeSpec) -> STypeRelation {
    func relation(from entry: STypeSpec.Entry?, to other: String) -> STypeRelation? {
      if let synergizes = entry?.synergizesWith, synergizes.contains(other) { return .synergy }
      if let stabilizes = entry?.stabilizesWith, stabilizes.contains(other) { return .stability }
      if let strains = entry?.strainsWith, strains.contains(other) { return .strain }
      return nil
    }

    let forward = relation(from: spec.types[a], to: b)
    let backward = relation(from: spec.types[b], to: a)
    return dominantRelation(from: [forward, backward])
  }

  private static func dominantRelation(from candidates: [STypeRelation?]) -> STypeRelation {
    let resolved = candidates.compactMap { $0 }
    if resolved.contains(.synergy) { return .synergy }
    if resolved.contains(.stability) { return .stability }
    if resolved.contains(.strain) { return .strain }
    return .neutral
  }

  private static func sharesTuple(_ metrics: STypeMixMetrics) -> (
    synergy: Double, stability: Double, strain: Double
  ) {
    return (metrics.synergyShare, metrics.stabilityShare, metrics.strainShare)
  }

  private static func composite(_ shares: (synergy: Double, stability: Double, strain: Double))
    -> Double
  {
    shares.synergy + shares.stability - shares.strain
  }
}
