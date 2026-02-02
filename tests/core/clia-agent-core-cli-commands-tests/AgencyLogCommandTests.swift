import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

@Test("Creates 0.4.0 ContributionEntry and minimal group")
func createsV040Entry() async throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  // Minimal repo marker for lineage resolution
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  _ = try AgencyLogCore.apply(
    startingAt: tmp,
    slug: "test-agent",
    summary: "hello",
    kind: "log",
    title: nil,
    detailItems: [],
    detailsText: nil,
    participants: [],
    tags: [],
    linkArgs: [],
    contributionArgs: [],
    createIfMissing: true,
    upsert: false,
    timestamp: ISO8601DateFormatter().string(from: Date())
  )

  let docURL =
    tmp
    .appendingPathComponent(".clia/agents/test-agent/test-agent@sample.agency.triad.json")
  let data = try Data(contentsOf: docURL)
  let doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
  #expect(doc.schemaVersion == TriadSchemaVersion.current)
  #expect(doc.entries.count == 1)
  let e = doc.entries[0]
  #expect(e.contributionGroups.count == 1)
  #expect(e.contributionGroups[0].by == "test-agent")
  #expect(e.contributionGroups[0].types.count == 1)
  #expect(e.contributionGroups[0].types[0].type == "log")
  #expect(e.contributionGroups[0].types[0].evidence == "hello")
}

@Test("Upserts by date+title when provided")
func upsertsByTitle() async throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  // First write
  do {
    _ = try AgencyLogCore.apply(
      startingAt: tmp,
      slug: "alpha",
      summary: "first",
      kind: "journal",
      title: "Daily",
      detailItems: [],
      detailsText: nil,
      participants: [],
      tags: [],
      linkArgs: [],
      contributionArgs: [],
      createIfMissing: true,
      upsert: false,
      timestamp: ISO8601DateFormatter().string(from: Date())
    )
  }

  // Second write with upsert and changed summary
  do {
    _ = try AgencyLogCore.apply(
      startingAt: tmp,
      slug: "alpha",
      summary: "second",
      kind: "journal",
      title: "Daily",
      detailItems: [],
      detailsText: nil,
      participants: [],
      tags: [],
      linkArgs: [],
      contributionArgs: [],
      createIfMissing: false,
      upsert: true,
      timestamp: ISO8601DateFormatter().string(from: Date())
    )
  }

  let url = tmp.appendingPathComponent(".clia/agents/alpha/alpha@sample.agency.triad.json")
  let data = try Data(contentsOf: url)
  let doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
  #expect(doc.entries.count == 1)
  #expect(doc.entries[0].summary == "second")
}

@Test("Explicit contribs and links map to typed fields")
func explicitContribsAndLinks() async throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  let c1 = AgencyContributionArg(by: "alice", type: "code", evidence: "PR #123", weight: 2)
  let c2 = AgencyContributionArg(by: "bob", type: "design", evidence: "Figma", weight: 1.5)

  _ = try AgencyLogCore.apply(
    startingAt: tmp,
    slug: "beta",
    summary: "sum",
    kind: "journal",
    title: "Entry",
    detailItems: ["d1"],
    detailsText: "d2",
    participants: [],
    tags: [],
    linkArgs: ["https://example.com/pr/42|pr|PR 42", "https://example.com/docs"],
    contributionArgs: [c1, c2],
    createIfMissing: true,
    upsert: false,
    timestamp: ISO8601DateFormatter().string(from: Date())
  )

  let url = tmp.appendingPathComponent(".clia/agents/beta/beta@sample.agency.triad.json")
  let data = try Data(contentsOf: url)
  let doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
  #expect(doc.entries.count == 1)
  let e = doc.entries[0]
  // Links
  let links = (e.links ?? [])
  #expect(links.count == 2)
  let linkMap = Dictionary(uniqueKeysWithValues: links.map { ($0.url ?? "", $0.title ?? "") })
  #expect(linkMap["https://example.com/pr/42"] == "PR 42")
  #expect(linkMap["https://example.com/docs"] == "")
  // Contributions
  var groupMap: [String: [ContributionItem]] = [:]
  for g in e.contributionGroups { groupMap[g.by] = g.types }
  if let items = groupMap["alice"] {
    #expect(items.count == 1)
    #expect(items[0].type == "code")
    #expect(items[0].evidence == "PR #123")
    #expect(items[0].weight == 2)
  } else {
    Issue.record("Missing alice group")
  }
  if let items = groupMap["bob"] {
    #expect(items.count == 1)
    #expect(items[0].type == "design")
    #expect(items[0].evidence == "Figma")
    #expect(items[0].weight == 1.5)
  } else {
    Issue.record("Missing bob group")
  }
}

@Test("Entries are sorted newest-first by timestamp")
func sortsNewestFirst() async throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  // Write an older entry first
  _ = try AgencyLogCore.apply(
    startingAt: tmp,
    slug: "gamma",
    summary: "older",
    kind: "journal",
    title: "A",
    detailItems: [],
    detailsText: nil,
    participants: [],
    tags: [],
    linkArgs: [],
    contributionArgs: [],
    createIfMissing: true,
    upsert: false,
    timestamp: "2025-09-01T12:00:00Z"
  )

  // Then write a newer entry
  _ = try AgencyLogCore.apply(
    startingAt: tmp,
    slug: "gamma",
    summary: "newer",
    kind: "journal",
    title: "B",
    detailItems: [],
    detailsText: nil,
    participants: [],
    tags: [],
    linkArgs: [],
    contributionArgs: [],
    createIfMissing: false,
    upsert: false,
    timestamp: "2025-09-02T08:00:00Z"
  )

  let url = tmp.appendingPathComponent(".clia/agents/gamma/gamma@sample.agency.triad.json")
  let data = try Data(contentsOf: url)
  let doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
  #expect(doc.entries.count == 2)
  #expect(doc.entries[0].title == "B")  // newer first
  #expect(doc.entries[1].title == "A")
}
