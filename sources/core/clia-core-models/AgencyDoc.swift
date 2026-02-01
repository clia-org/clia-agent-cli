import Foundation

public struct AgencyDoc: Codable, Sendable {
  public var schemaVersion: String
  public var slug: String
  public var title: String
  public var updated: String
  public var status: String?
  public var sourcePath: String?
  public var mentors: [String]
  public var tags: [String]
  public var links: [LinkRef]
  public var entries: [AgencyEntry]
  public var sections: [Section]
  public var notes: [Note]
  public var extensions: [String: ExtensionValue]?

  public init(
    schemaVersion: String = TriadSchemaVersion.current,
    slug: String,
    title: String,
    updated: String,
    status: String? = nil,
    sourcePath: String? = nil,
    mentors: [String] = [],
    tags: [String] = [],
    links: [LinkRef] = [],
    entries: [AgencyEntry] = [],
    sections: [Section] = [],
    notes: [Note] = [],
    extensions: [String: ExtensionValue]? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.slug = slug
    self.title = title
    self.updated = updated
    self.status = status
    self.sourcePath = sourcePath
    self.mentors = mentors
    self.tags = tags
    self.links = links
    self.entries = entries
    self.sections = sections
    self.notes = notes
    self.extensions = extensions
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion, slug, title, updated, status, sourcePath, mentors, tags, links, entries,
      sections, notes,
      extensions
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let decodedSchemaVersion = try c.decode(String.self, forKey: .schemaVersion)
    guard decodedSchemaVersion == TriadSchemaVersion.current else {
      throw DecodingError.dataCorruptedError(
        forKey: .schemaVersion,
        in: c,
        debugDescription: "Expected schemaVersion \(TriadSchemaVersion.current)"
      )
    }
    self.schemaVersion = decodedSchemaVersion
    self.slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
    self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    self.updated = try c.decodeIfPresent(String.self, forKey: .updated) ?? ""
    self.status = try c.decodeIfPresent(String.self, forKey: .status)
    self.sourcePath = try c.decodeIfPresent(String.self, forKey: .sourcePath)
    self.mentors = try c.decodeIfPresent([String].self, forKey: .mentors) ?? []
    self.tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    self.links = try c.decodeIfPresent([LinkRef].self, forKey: .links) ?? []
    self.entries = try c.decodeIfPresent([AgencyEntry].self, forKey: .entries) ?? []
    if let typedSec = try c.decodeIfPresent([Section].self, forKey: .sections) {
      self.sections = typedSec
    } else if let flatSec = try? c.decodeIfPresent([String].self, forKey: .sections) {
      self.sections = AgentDoc.sectionsFromFlat(flatSec)
    } else {
      self.sections = []
    }
    self.notes = try c.decodeIfPresent([Note].self, forKey: .notes) ?? []
    self.extensions = try c.decodeIfPresent([String: ExtensionValue].self, forKey: .extensions)
  }
}
