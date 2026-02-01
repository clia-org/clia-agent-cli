import Foundation

public struct ContextItem {
  public let dir: URL
  public let agentURL: URL
  public let prefix: String
  public let weight: Int
  public init(dir: URL, agentURL: URL, prefix: String, weight: Int) {
    self.dir = dir
    self.agentURL = agentURL
    self.prefix = prefix
    self.weight = weight
  }
}
