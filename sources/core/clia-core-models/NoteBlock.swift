import Foundation

public struct NoteBlock: Codable, Sendable {
  public var kind: String
  public var text: [String]
  public init(kind: String, text: [String]) {
    self.kind = kind
    self.text = text
  }
}
