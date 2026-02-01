import Foundation

public struct Note: Codable, Sendable {
  public var timestamp: String?
  public var author: String?
  public var blocks: [NoteBlock]
  public var tags: [String]?
  public var links: [LinkRef]?
  public var extensions: [String: ExtensionValue]?

  public init(
    timestamp: String? = nil,
    author: String? = nil,
    blocks: [NoteBlock] = [],
    tags: [String]? = nil,
    links: [LinkRef]? = nil,
    extensions: [String: ExtensionValue]? = nil
  ) {
    self.timestamp = timestamp
    self.author = author
    self.blocks = blocks
    self.tags = tags
    self.links = links
    self.extensions = extensions
  }
}
