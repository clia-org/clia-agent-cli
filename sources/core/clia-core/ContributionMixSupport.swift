import CLIACoreModels
import Foundation

public enum ContributionMixSupport {
  /// Resolve normalized primary contribution shares for an agent by merging triads.
  /// - Returns: map type -> share (empty when no contributionMix present)
  public static func normalizedPrimaryShares(slug: String, under root: URL) -> [String: Double] {
    let merged = Merger.mergeAgent(slug: slug, under: root)
    return merged.contributionMix?.normalizedPrimary() ?? [:]
  }

  /// Return the union of primary and secondary contribution types for the given mix.
  public static func contributionTypes(from mix: ContributionMix?) -> Set<String> {
    guard let mix else { return [] }
    var out = Set<String>()
    for c in mix.primary { out.insert(c.type) }
    if let secondary = mix.secondary {
      for c in secondary { out.insert(c.type) }
    }
    return out
  }
}
