import Foundation

/// A lightweight reference to an agent identity used across triads.
///
/// - slug: Canonical kebab-case identifier (required).
/// - role: Optional display role (human-facing); do not use for lookups.
/// - scope: Optional free-form qualifier (e.g., product area or path).
/// - lLevel: Optional abstraction level tag (L0…L4).
public struct AgentRef: Codable, Sendable {
  public var slug: String
  public var role: String?
  public var scope: String?
  public var lLevel: String?

  public init(slug: String, role: String? = nil, scope: String? = nil, lLevel: String? = nil) {
    self.slug = slug
    self.role = role
    self.scope = scope
    self.lLevel = lLevel
  }
}
