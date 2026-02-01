import Foundation

public struct Horizon: Codable, Sendable {
  public var slug: String
  public var title: String
  public var kind: String?
  public var items: [String]

  public init(slug: String, title: String, kind: String? = nil, items: [String]) {
    self.slug = slug
    self.title = title
    self.kind = kind
    self.items = items
  }
}
