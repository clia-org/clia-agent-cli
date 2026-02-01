import CLIACoreModels
import Foundation

public struct MergedAgentView: Codable, Sendable {
  public var schemaVersion: String
  public var slug: String
  public var title: String
  public var updated: String
  public var status: String?
  public var role: String
  public var mentors: [String]
  public var tags: [String]
  public var links: [LinkRef]
  public var purpose: String?
  public var responsibilities: [String]
  public var guardrails: [String]
  public var checklists: [String]
  public var sections: [String]
  public var notes: [Note]
  public var avatarPath: String?
  public var figletFontName: String?
  public var extensions: [String: ExtensionValue]?
  public var emojiTags: [String]
  public var contributionMix: ContributionMix? = nil
  public var persona: PersonaRefs? = nil
  public var systemInstructions: SystemInstructionsRefs? = nil
  public var cliSpec: CLISpecExport? = nil
  public var contextChain: [ContextEntry]? = nil
  public var origin: Origin? = nil
}
