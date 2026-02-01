import CLIAAgentCore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

internal enum AgendaNormalizeCore {
  enum BacklogSortOption {
    case none
    case title
    case id
  }

  @discardableResult
  static func apply(
    startingAt cwd: URL,
    slug: String,
    write: Bool,
    backlogSort: BacklogSortOption
  ) throws -> (changed: Bool, path: URL) {
    let target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
    let url = triadPath(in: target.agentDir, slug: slug, kind: "agenda")
    let changed = try applyFile(url: url, write: write, backlogSort: backlogSort)
    return (changed, url)
  }

  @discardableResult
  static func applyFile(url: URL, write: Bool, backlogSort: BacklogSortOption) throws -> Bool {
    let fm = FileManager.default
    guard fm.fileExists(atPath: url.path) else { return false }
    let originalData = try Data(contentsOf: url)
    var doc = try JSONDecoder().decode(AgendaDoc.self, from: originalData)
    let origMilestones = doc.milestones
    let origBacklog = doc.backlog

    doc.milestones = sortMilestones(origMilestones)
    if backlogSort != .none { doc.backlog = sortBacklogItems(origBacklog, by: backlogSort) }

    let orderChanged =
      !equalMilestones(doc.milestones, origMilestones) || !equalBacklog(doc.backlog, origBacklog)
    if orderChanged { doc.updated = ISO8601DateFormatter().string(from: Date()) }

    let enc = JSON.Formatting.humanEncoder
    var normalized = try enc.encode(doc)
    if normalized.last != 0x0A { normalized.append(0x0A) }
    let bytesDiffer = normalized != originalData
    if write && bytesDiffer {
      try JSON.FileWriter.write(doc, to: url, encoder: enc)
      FormattingFinalizer.finalizeJSON(at: url)
    }
    return orderChanged || bytesDiffer
  }

  private static func equalMilestones(_ a: [Milestone], _ b: [Milestone]) -> Bool {
    guard a.count == b.count else { return false }
    for (l, r) in zip(a, b)
    where l.slug != r.slug || l.title != r.title || l.due != r.due || l.status != r.status {
      return false
    }
    return true
  }

  private static func equalBacklog(_ a: [BacklogItem], _ b: [BacklogItem]) -> Bool {
    guard a.count == b.count else { return false }
    for (l, r) in zip(a, b) where l.title != r.title || l.slug != r.slug {
      return false
    }
    return true
  }

  private static func sortMilestones(_ arr: [Milestone]) -> [Milestone] {
    let bucketIndex: (String?) -> Int = { status in
      switch status?.lowercased() {
      case "planned": return 0
      case "in-progress": return 1
      case "at-risk": return 2
      case "done": return 3
      case "dropped": return 5
      default: return 4  // unknown just before dropped
      }
    }
    func parseDue(_ s: String?) -> Date? {
      guard let s, !s.isEmpty else { return nil }
      // Try yyyy-MM-dd first
      let df = DateFormatter()
      df.locale = Locale(identifier: "en_US_POSIX")
      df.dateFormat = "yyyy-MM-dd"
      if let d = df.date(from: s) { return d }
      // Fallback to ISO 8601 date-time
      if let d = ISO8601DateFormatter().date(from: s) { return d }
      return nil
    }
    return arr.sorted { l, r in
      let lb = bucketIndex(l.status)
      let rb = bucketIndex(r.status)
      if lb != rb { return lb < rb }
      let ld = parseDue(l.due)
      let rd = parseDue(r.due)
      switch (ld, rd) {
      case (nil, nil): break
      case (nil, _?): return false
      case (_?, nil): return true
      case (let ldt?, let rdt?): if ldt != rdt { return ldt < rdt }
      }
      // tie-breaker: title asc (case-insensitive)
      return l.title.lowercased() < r.title.lowercased()
    }
  }

  private static func sortBacklogItems(_ arr: [BacklogItem], by opt: BacklogSortOption)
    -> [BacklogItem]
  {
    switch opt {
    case .none: return arr
    case .title:
      return arr.sorted { a, b in a.title.lowercased() < b.title.lowercased() }
    case .id:
      // Use slug as identifier; items without slug go last, then by title
      return arr.sorted { a, b in
        switch (a.slug, b.slug) {
        case (nil, nil): return a.title.lowercased() < b.title.lowercased()
        case (nil, _?): return false
        case (_?, nil): return true
        case (let asg?, let bsg?):
          if asg != bsg { return asg < bsg }
          return a.title.lowercased() < b.title.lowercased()
        }
      }
    }
  }

  private static func triadPath(in dir: URL, slug: String, kind: String) -> URL {
    let fm = FileManager.default
    if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      if let match = contents.first(where: { $0.lastPathComponent.hasSuffix(".\(kind).json") }) {
        return match
      }
    }
    let dirTag =
      dir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .lastPathComponent
    return dir.appendingPathComponent("\(slug)@\(dirTag).\(kind).json")
  }
}
