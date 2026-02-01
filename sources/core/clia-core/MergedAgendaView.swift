import CLIACoreModels
import Foundation

public struct MergedAgendaView: Codable, Sendable {
  public var schemaVersion: String
  public var slug: String
  public var title: String
  public var subtitle: String?
  public var updated: String
  public var status: String?
  public var agent: AgendaAgentRef
  public var mentors: [String]
  public var tags: [String]
  public var links: [LinkRef]
  public var northStar: String?
  public var principles: [String]
  public var themes: [String]
  public var horizons: [String]
  public var initiatives: [String]
  public var milestones: [String]
  public var backlog: [String]
  public var metrics: String?
  public var cadence: String?
  public var dependencies: [String]
  public var risks: [String]
  public var crossLinks: String?
  public var sections: [String]
  public var notes: [Note]
  public var extensions: [String: ExtensionValue]?
  public var contextChain: [ContextEntry]? = nil
  public var origin: Origin? = nil
}
