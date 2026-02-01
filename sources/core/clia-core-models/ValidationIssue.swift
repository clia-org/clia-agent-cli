import Foundation

public struct ValidationIssue: Codable, Sendable, CustomStringConvertible {
  public var kind: ValidationIssueKind
  public var message: String

  public init(kind: ValidationIssueKind, message: String) {
    self.kind = kind
    self.message = message
  }

  public var description: String { "[\(kind)] \(message)" }
}
