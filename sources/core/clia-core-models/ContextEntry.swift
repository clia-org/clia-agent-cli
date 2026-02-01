import Foundation

// Context lineage entry: identifies a contributing layer in merged views
public struct ContextEntry: Codable, Sendable {
  public var prefix: String
  public var path: String
  public init(prefix: String, path: String) {
    self.prefix = prefix
    self.path = path
  }
}
