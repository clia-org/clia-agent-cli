import Foundation

public struct ResponseHeader: Codable, Sendable {
  public var defaults: ResponseHeaderDefaults?
  public var rendering: ResponseHeaderRendering?

  public init(defaults: ResponseHeaderDefaults? = nil, rendering: ResponseHeaderRendering? = nil) {
    self.defaults = defaults
    self.rendering = rendering
  }
}
