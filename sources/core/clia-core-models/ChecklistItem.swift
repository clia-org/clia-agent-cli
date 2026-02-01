import Foundation

public struct ChecklistItem: Codable, Sendable {
  public var text: String
  public var level: ChecklistLevel

  public init(text: String, level: ChecklistLevel = .required) {
    self.text = text
    self.level = level
  }

  public init(from decoder: Decoder) throws {
    if let single = try? decoder.singleValueContainer(), let s = try? single.decode(String.self) {
      self.text = s
      self.level = .required
      return
    }
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.text = try c.decode(String.self, forKey: .text)
    self.level = (try? c.decode(ChecklistLevel.self, forKey: .level)) ?? .required
  }

  enum CodingKeys: String, CodingKey { case text, level }
}
