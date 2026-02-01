import Foundation

/// An evidenced contribution for Agency entries.
///
/// Adds a required `evidence` string to a base `Contribution` to provide an
/// audit trail (for example, "PR #42", a link, or ticket id).
public struct ContributionItem: Codable, Sendable {
  public var type: String
  public var weight: Double
  public var evidence: String

  public init(type: String, weight: Double, evidence: String) {
    self.type = type
    self.weight = weight
    self.evidence = evidence
  }
}
