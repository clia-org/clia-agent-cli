import Foundation

public enum ChecklistLevel: String, Codable, Sendable {
  case required
  case optional
  case disabled
}
