import Foundation

public struct Section: Codable, Sendable {
  public var title: String?
  public var slug: String?
  public var kind: String?
  public var items: [String]

  public init(title: String? = nil, slug: String? = nil, kind: String? = nil, items: [String] = [])
  {
    self.title = title
    self.slug = slug
    self.kind = kind
    self.items = items
  }
}
