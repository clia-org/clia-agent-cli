import Foundation

public struct BacklogItem: Codable, Sendable {
  public var title: String
  public var slug: String?
  public var notes: [String]?
  public var links: [LinkRef]?
  public var expectedContributions: ExpectedContributions?

  public init(
    title: String,
    slug: String? = nil,
    notes: [String]? = nil,
    links: [LinkRef]? = nil,
    expectedContributions: ExpectedContributions? = nil
  ) {
    self.title = title
    self.slug = slug
    self.notes = notes
    self.links = links
    self.expectedContributions = expectedContributions
  }
}
