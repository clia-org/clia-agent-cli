import Foundation

public struct ResponseHeaderDefaults: Codable, Sendable {
  public var mode: String?
  public var title: String?
  public var attendeeEmojis: String?
  public var attendees: [String]?

  public init(
    mode: String? = nil,
    title: String? = nil,
    attendeeEmojis: String? = nil,
    attendees: [String]? = nil
  ) {
    self.mode = mode
    self.title = title
    self.attendeeEmojis = attendeeEmojis
    self.attendees = attendees
  }
}
