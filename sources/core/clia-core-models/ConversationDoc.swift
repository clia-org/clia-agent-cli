import Foundation

public struct ConversationDoc: Codable, Sendable {
  public var schemaVersion: String
  public var id: String
  public var title: String?
  public var kind: String
  public var status: String
  public var created: String
  public var updated: String
  public var participants: [String]
  public var headerOverrides: ConversationHeaderOverrides?
  public var tags: [String]
  public var links: [LinkRef]
  public var notes: [Note]
  public var attachments: [LinkRef]?
  public var extensions: [String: ExtensionValue]?

  public init(
    schemaVersion: String = "0.1.0",
    id: String,
    title: String? = nil,
    kind: String,
    status: String,
    created: String,
    updated: String,
    participants: [String] = [],
    headerOverrides: ConversationHeaderOverrides? = nil,
    tags: [String] = [],
    links: [LinkRef] = [],
    notes: [Note] = [],
    attachments: [LinkRef]? = nil,
    extensions: [String: ExtensionValue]? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.id = id
    self.title = title
    self.kind = kind
    self.status = status
    self.created = created
    self.updated = updated
    self.participants = participants
    self.headerOverrides = headerOverrides
    self.tags = tags
    self.links = links
    self.notes = notes
    self.attachments = attachments
    self.extensions = extensions
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case id
    case title
    case kind
    case status
    case created
    case updated
    case participants
    case headerOverrides
    case tags
    case links
    case notes
    case attachments
    case extensions
  }
}
