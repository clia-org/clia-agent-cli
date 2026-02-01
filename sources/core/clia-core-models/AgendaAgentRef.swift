import Foundation

public struct AgendaAgentRef: Codable, Sendable {
  public var role: String
  public var scope: String?
  public var lLevel: String?

  public init(role: String, scope: String? = nil, lLevel: String? = nil) {
    self.role = role
    self.scope = scope
    self.lLevel = lLevel
  }
}
