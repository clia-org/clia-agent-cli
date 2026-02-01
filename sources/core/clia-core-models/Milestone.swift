import Foundation

public struct Milestone: Codable, Sendable {
  public var slug: String
  public var title: String
  public var due: String?
  public var status: String?
  public var completedAt: String?
  public var notes: [String]?
  public var links: [LinkRef]?
  public var expectedContributions: ExpectedContributions?

  public init(
    slug: String,
    title: String,
    due: String? = nil,
    status: String? = nil,
    completedAt: String? = nil,
    notes: [String]? = nil,
    links: [LinkRef]? = nil,
    expectedContributions: ExpectedContributions? = nil
  ) {
    self.slug = slug
    self.title = title
    self.due = due
    self.status = status
    self.completedAt = completedAt
    self.notes = notes
    self.links = links
    self.expectedContributions = expectedContributions
  }
}
