import Foundation

public struct Notes: Codable, Sendable {
  public var author: String?
  public var date: String?
  public var blocks: [NoteBlock]?

  public init(author: String?, date: String?, blocks: [NoteBlock]?) {
    self.author = author
    self.date = date
    self.blocks = blocks
  }
}
