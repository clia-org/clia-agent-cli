import Foundation

public struct Incident: Codable, Sendable {
  public var id: String
  public var title: String
  public var severity: IncidentSeverity
  public var status: String
  public var owner: String
  public var started: String

  public var summary: String?
  public var affectedPaths: [String]?
  public var doNotModify: [String]?
  public var blockedTools: [String]?
  public var links: [LinkRef]?
  public var extensions: [String: ExtensionValue]?

  public init(
    id: String,
    title: String,
    severity: IncidentSeverity,
    status: String,
    owner: String,
    started: String,
    summary: String? = nil,
    affectedPaths: [String]? = nil,
    doNotModify: [String]? = nil,
    blockedTools: [String]? = nil,
    links: [LinkRef]? = nil,
    extensions: [String: ExtensionValue]? = nil
  ) {
    self.id = id
    self.title = title
    self.severity = severity
    self.status = status
    self.owner = owner
    self.started = started
    self.summary = summary
    self.affectedPaths = affectedPaths
    self.doNotModify = doNotModify
    self.blockedTools = blockedTools
    self.links = links
    self.extensions = extensions
  }

  // MARK: - Presentation
  public var bannerText: String {
    "[INCIDENT — \(severity.string) — \(title)]"
  }
}
