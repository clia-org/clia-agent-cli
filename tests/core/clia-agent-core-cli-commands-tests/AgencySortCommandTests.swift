import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

@Test("agency-sort sorts entries newest-first and saves")
func agencySortApplies() async throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  // Seed an unsorted AgencyDoc (older first)
  let slug = "sorter"
  let url =
    tmp
    .appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agency.triad.json")
  try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  let eOld = AgencyEntry(
    timestamp: "2025-09-01T10:00:00Z",
    kind: "journal",
    title: "A",
    summary: "older",
    details: nil,
    tags: nil,
    links: nil,
    contributionGroups: [
      ContributionGroup(by: slug, types: [ContributionItem(type: "log", weight: 1, evidence: "x")])
    ],
    extensions: nil
  )
  let eNew = AgencyEntry(
    timestamp: "2025-09-02T10:00:00Z",
    kind: "journal",
    title: "B",
    summary: "newer",
    details: nil,
    tags: nil,
    links: nil,
    contributionGroups: [
      ContributionGroup(by: slug, types: [ContributionItem(type: "log", weight: 1, evidence: "y")])
    ],
    extensions: nil
  )
  let doc = AgencyDoc(
    slug: slug,
    title: "Sorter Agency",
    updated: "2025-09-01T00:00:00Z",
    status: "active",
    entries: [eOld, eNew]
  )
  let enc = JSONEncoder()
  enc.outputFormatting = [.prettyPrinted, .sortedKeys]
  try enc.encode(doc).write(to: url)

  // Apply via core helper
  _ = try AgencySortCore.apply(startingAt: tmp, slug: slug, write: true)

  let saved = try JSONDecoder().decode(AgencyDoc.self, from: Data(contentsOf: url))
  #expect(saved.entries.count == 2)
  #expect(saved.entries[0].title == "B")
  #expect(saved.entries[1].title == "A")
}
