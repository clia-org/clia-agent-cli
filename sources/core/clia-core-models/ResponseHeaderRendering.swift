import Foundation

public struct ResponseHeaderRendering: Codable, Sendable {
  public struct Templates: Codable, Sendable {
    public var line1: String?
    public var line2: String?
    public init(line1: String? = nil, line2: String? = nil) {
      self.line1 = line1
      self.line2 = line2
    }
  }

  public var templates: Templates?
  public var attendeesFormat: String?
  public var delimiter: String?

  public init(templates: Templates? = nil, attendeesFormat: String? = nil, delimiter: String? = nil)
  {
    self.templates = templates
    self.attendeesFormat = attendeesFormat
    self.delimiter = delimiter
  }
}
