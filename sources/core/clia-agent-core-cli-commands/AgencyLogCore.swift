import CLIAAgentCore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct AgencyContributionArg {
  public let by: String
  public let type: String
  public let evidence: String
  public let weight: Double?
  public init(by: String, type: String, evidence: String, weight: Double? = nil) {
    self.by = by
    self.type = type
    self.evidence = evidence
    self.weight = weight
  }
}

internal enum AgencyLogCore {
  @discardableResult
  static func apply(
    startingAt cwd: URL,
    slug: String,
    summary: String,
    kind: String,
    title: String?,
    detailItems: [String],
    detailsText: String?,
    participants: [String],
    tags: [String],
    linkArgs: [String],
    contributionArgs: [AgencyContributionArg],
    createIfMissing: Bool,
    upsert: Bool,
    timestamp: String
  ) throws -> URL {
    let target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
    let url = agencyTriadPath(in: target.agentDir, slug: slug)
    let fm = FileManager.default
    if !fm.fileExists(atPath: url.path) {
      guard createIfMissing else { return url }
      try createMinimalAgency(at: url, slug: slug, timestamp: timestamp)
    }
    let data = try Data(contentsOf: url)
    var doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
    let entry = makeTypedEntry(
      summary: summary,
      kind: kind,
      title: title,
      detailItems: detailItems,
      detailsText: detailsText,
      participants: participants,
      tags: tags,
      linkArgs: linkArgs,
      docSlug: slug,
      timestamp: timestamp,
      contributionArgs: contributionArgs
    )
    if upsert {
      doc.entries = upsertEntry(entries: doc.entries, newEntry: entry, timestamp: timestamp)
    } else {
      doc.entries.append(entry)
    }
    doc.entries =
      SortedArray(
        unsorted: doc.entries,
        sortOrder: { (l: AgencyEntry, r: AgencyEntry) in l.timestamp > r.timestamp }
      ).elements
    doc.updated = timestamp
    try JSON.FileWriter.write(doc, to: url)
    FormattingFinalizer.finalizeJSON(at: url)
    return url
  }

  private static func agencyTriadPath(in dir: URL, slug: String) -> URL {
    let fm = FileManager.default
    if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      if let match = contents.first(where: { $0.lastPathComponent.hasSuffix(".agency.json") }) {
        return match
      }
    }
    let dirTag =
      dir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .lastPathComponent
    return dir.appendingPathComponent("\(slug)@\(dirTag).agency.json")
  }

  static func makeTypedEntry(
    summary: String,
    kind: String,
    title: String?,
    detailItems: [String],
    detailsText: String?,
    participants: [String],
    tags: [String],
    linkArgs: [String],
    docSlug: String,
    timestamp: String,
    contributionArgs: [AgencyContributionArg]
  ) -> AgencyEntry {
    let combinedTags = (tags + participants)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
    var detailsArr: [String] = []
    if !detailItems.isEmpty { detailsArr.append(contentsOf: detailItems) }
    if let d = detailsText, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      detailsArr.append(d)
    }
    let linkRefs = parseLinksTyped(from: linkArgs)
    let groups = makeTypedContributionGroups(
      docSlug: docSlug, participants: participants, kind: kind, summary: summary,
      contributionArgs: contributionArgs)
    return AgencyEntry(
      timestamp: timestamp,
      kind: kind.isEmpty ? nil : kind,
      title: title,
      summary: summary.isEmpty ? nil : summary,
      details: detailsArr.isEmpty ? nil : detailsArr,
      tags: combinedTags.isEmpty ? nil : combinedTags,
      links: linkRefs.isEmpty ? nil : linkRefs,
      contributionGroups: groups,
      extensions: nil
    )
  }

  static func parseLinksTyped(from args: [String]) -> [LinkRef] {
    var out: [LinkRef] = []
    for a in args {
      let parts = a.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
      guard !parts.isEmpty else { continue }
      let href = parts[0]
      let title = parts.count > 2 ? (parts[2].isEmpty ? nil : parts[2]) : nil
      out.append(LinkRef(title: title, url: href))
    }
    return out
  }

  static func makeTypedContributionGroups(
    docSlug: String,
    participants: [String],
    kind: String,
    summary: String,
    contributionArgs: [AgencyContributionArg]
  ) -> [ContributionGroup] {
    if !contributionArgs.isEmpty {
      var grouped: [String: [ContributionItem]] = [:]
      for spec in contributionArgs {
        let item = ContributionItem(
          type: spec.type, weight: spec.weight ?? 1, evidence: spec.evidence)
        grouped[spec.by, default: []].append(item)
      }
      return grouped.map { ContributionGroup(by: $0.key, types: $0.value) }
    }
    let actors = participants.isEmpty ? [docSlug] : participants
    let item = ContributionItem(type: kind.isEmpty ? "log" : kind, weight: 1, evidence: summary)
    return actors.map { ContributionGroup(by: $0, types: [item]) }
  }

  static func upsertEntry(
    entries: [AgencyEntry], newEntry: AgencyEntry, timestamp: String
  ) -> [AgencyEntry] {
    var out = entries
    let datePrefix: String = timestamp.split(separator: "T").first.map(String.init) ?? timestamp
    let matchTitle = newEntry.title
    let matchKind = newEntry.kind
    if let idx = out.firstIndex(where: { e in
      let ts = e.timestamp
      guard ts.hasPrefix(datePrefix) else { return false }
      if let t = matchTitle, let et = e.title { return et == t }
      if let k = matchKind, let ek = e.kind { return ek == k }
      return false
    }) {
      out[idx] = newEntry
      return out
    }
    out.append(newEntry)
    return out
  }

  static func createMinimalAgency(at url: URL, slug: String, timestamp: String) throws {
    let dir = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let doc = AgencyDoc(
      schemaVersion: TriadSchemaVersion.current,
      slug: slug,
      title: "\(slug.capitalized) Agency",
      updated: timestamp,
      status: "active",
      entries: []
    )
    try JSON.FileWriter.write(doc, to: url)
    FormattingFinalizer.finalizeJSON(at: url)
  }
}
