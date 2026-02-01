import CLIACoreModels
import Foundation

public struct MergedAgencyView: Codable, Sendable {
  public var schemaVersion: String
  public var slug: String
  public var title: String
  public var updated: String
  public var status: String?
  public var mentors: [String]
  public var tags: [String]
  public var links: [LinkRef]
  public var entries: [AgencyEntry]
  public var sections: [String]
  public var notes: [Note]
  public var extensions: [String: ExtensionValue]?
  public var contextChain: [ContextEntry]? = nil
  public var origin: Origin? = nil
}
