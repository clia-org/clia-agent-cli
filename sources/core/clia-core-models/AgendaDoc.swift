import Foundation

public struct AgendaDoc: Codable, Sendable {
  public var schemaVersion: String
  public var slug: String
  public var title: String
  public var subtitle: String?
  public var updated: String
  public var status: String?
  public var sourcePath: String?
  public var agent: AgendaAgentRef
  public var mentors: [String]
  public var tags: [String]
  public var links: [LinkRef]
  public var northStar: String?
  public var principles: [String]
  public var themes: [String]
  public var horizons: [Horizon]
  public var initiatives: [String]
  public var milestones: [Milestone]
  public var backlog: [BacklogItem]
  public var metrics: String?
  public var cadence: String?
  public var dependencies: [String]
  public var risks: [String]
  public var crossLinks: String?
  public var sections: [Section]
  public var notes: [Note]
  public var extensions: [String: ExtensionValue]?

  public init(
    schemaVersion: String = TriadSchemaVersion.current,
    slug: String,
    title: String,
    subtitle: String? = nil,
    updated: String,
    status: String? = nil,
    sourcePath: String? = nil,
    agent: AgendaAgentRef,
    mentors: [String] = [],
    tags: [String] = [],
    links: [LinkRef] = [],
    northStar: String? = nil,
    principles: [String] = [],
    themes: [String] = [],
    horizons: [Horizon] = [],
    initiatives: [String] = [],
    milestones: [Milestone] = [],
    backlog: [BacklogItem] = [],
    metrics: String? = nil,
    cadence: String? = nil,
    dependencies: [String] = [],
    risks: [String] = [],
    crossLinks: String? = nil,
    sections: [Section] = [],
    notes: [Note] = [],
    extensions: [String: ExtensionValue]? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.slug = slug
    self.title = title
    self.subtitle = subtitle
    self.updated = updated
    self.status = status
    self.sourcePath = sourcePath
    self.agent = agent
    self.mentors = mentors
    self.tags = tags
    self.links = links
    self.northStar = northStar
    self.principles = principles
    self.themes = themes
    self.horizons = horizons
    self.initiatives = initiatives
    self.milestones = milestones
    self.backlog = backlog
    self.metrics = metrics
    self.cadence = cadence
    self.dependencies = dependencies
    self.risks = risks
    self.crossLinks = crossLinks
    self.sections = sections
    self.notes = notes
    self.extensions = extensions
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion, slug, title, subtitle, updated, status, sourcePath, agent, mentors, tags,
      links
    case northStar, principles, themes, horizons, initiatives, milestones, backlog
    case metrics, cadence, dependencies, risks, crossLinks, sections, notes, extensions
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
    self.subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
    self.updated = try c.decodeIfPresent(String.self, forKey: .updated) ?? ""
    self.status = try c.decodeIfPresent(String.self, forKey: .status)
    self.sourcePath = try c.decodeIfPresent(String.self, forKey: .sourcePath)
    self.agent = try c.decodeIfPresent(AgendaAgentRef.self, forKey: .agent) ?? .init(role: "")
    self.mentors = try c.decodeIfPresent([String].self, forKey: .mentors) ?? []
    self.tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    self.links = try c.decodeIfPresent([LinkRef].self, forKey: .links) ?? []
    self.northStar = try c.decodeIfPresent(String.self, forKey: .northStar)
    self.principles = try c.decodeIfPresent([String].self, forKey: .principles) ?? []
    self.themes = try c.decodeIfPresent([String].self, forKey: .themes) ?? []
    if let typedH = try c.decodeIfPresent([Horizon].self, forKey: .horizons) {
      self.horizons = typedH
    } else if let flatH = try? c.decodeIfPresent([String].self, forKey: .horizons) {
      self.horizons = flatH.map { s in Horizon(slug: "legacy", title: s, kind: nil, items: []) }
    } else {
      self.horizons = []
    }
    self.initiatives = try c.decodeIfPresent([String].self, forKey: .initiatives) ?? []
    if let typedM = try c.decodeIfPresent([Milestone].self, forKey: .milestones) {
      self.milestones = typedM
    } else if let flatM = try? c.decodeIfPresent([String].self, forKey: .milestones) {
      self.milestones = flatM.map { s in
        Milestone(slug: "", title: s, due: nil, status: nil, notes: nil, links: nil)
      }
    } else {
      self.milestones = []
    }
    if let typedB = try c.decodeIfPresent([BacklogItem].self, forKey: .backlog) {
      self.backlog = typedB
    } else if let flatB = try? c.decodeIfPresent([String].self, forKey: .backlog) {
      self.backlog = flatB.map { s in BacklogItem(title: s, slug: nil, notes: nil, links: nil) }
    } else {
      self.backlog = []
    }
    self.metrics = try c.decodeIfPresent(String.self, forKey: .metrics)
    self.cadence = try c.decodeIfPresent(String.self, forKey: .cadence)
    self.dependencies = try c.decodeIfPresent([String].self, forKey: .dependencies) ?? []
    self.risks = try c.decodeIfPresent([String].self, forKey: .risks) ?? []
    self.crossLinks = try c.decodeIfPresent(String.self, forKey: .crossLinks)
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
