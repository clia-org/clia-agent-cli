import Foundation

public struct Origin: Codable, Sendable {
  public var firstObservedAt: String?
  public var provenance: [OriginProvenance]

  public init(firstObservedAt: String?, provenance: [OriginProvenance]) {
    self.firstObservedAt = firstObservedAt
    self.provenance = provenance
  }
}

public struct OriginProvenance: Codable, Sendable {
  public var source: String
  public var path: String?
  public var value: String
  public var inheritedFrom: String?

  public init(source: String, path: String? = nil, value: String, inheritedFrom: String? = nil) {
    self.source = source
    self.path = path
    self.value = value
    self.inheritedFrom = inheritedFrom
  }
}
