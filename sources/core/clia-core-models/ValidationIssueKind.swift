import Foundation

public enum ValidationIssueKind: String, Codable, Sendable {
  case error
  case warning
}
