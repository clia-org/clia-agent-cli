import Foundation

/// A minimal person reference used in triads for ownership and attribution.
///
/// Only `name` is required; other fields are optional and may be filled as
/// integrations mature (for example, GitHub or Slack handles).
public struct PersonRef: Codable, Sendable {
  public var name: String
  public var email: String?
  public var github: String?
  public var slack: String?

  public init(name: String, email: String? = nil, github: String? = nil, slack: String? = nil) {
    self.name = name
    self.email = email
    self.github = github
    self.slack = slack
  }
}
