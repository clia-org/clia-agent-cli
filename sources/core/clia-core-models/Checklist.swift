import Foundation

public struct Checklist: Codable, Sendable {
  public var title: String?
  public var items: [ChecklistItem]

  public init(title: String? = nil, items: [ChecklistItem] = []) {
    self.title = title
    self.items = items
  }
}
