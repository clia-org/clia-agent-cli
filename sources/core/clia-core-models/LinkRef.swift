import Foundation

public struct LinkRef: Codable, Sendable {
  public var title: String?
  public var url: String?

  public init(title: String? = nil, url: String? = nil) {
    self.title = title
    self.url = url
  }
}
