import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

@Test("Agenda normalize: milestone bucket + due ordering")
func agendaNormalizeMilestones() throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  let slug = "norm-agenda"
  let url = tmp.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agenda.triad.json")
  try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

  let ms: [Milestone] = [
    Milestone(slug: "m2", title: "InProg", due: "2025-09-02", status: "in-progress"),
    Milestone(slug: "m1", title: "Planned", due: "2025-08-01", status: "planned"),
    Milestone(slug: "m4", title: "Unknown", due: nil, status: nil),
    Milestone(slug: "m5", title: "Dropped", due: "2025-07-01", status: "dropped"),
    Milestone(slug: "m3", title: "Done", due: "2025-10-01", status: "done"),
  ]
  let doc = AgendaDoc(
    slug: slug,
    title: "Agenda",
    updated: "2025-09-01T00:00:00Z",
    status: "active",
    agent: .init(role: slug),
    milestones: ms
  )
  let enc = JSONEncoder()
  enc.outputFormatting = [.prettyPrinted, .sortedKeys]
  try enc.encode(doc).write(to: url)

  // Apply normalization
  _ = try AgendaNormalizeCore.apply(startingAt: tmp, slug: slug, write: true, backlogSort: .none)
  let saved = try JSONDecoder().decode(AgendaDoc.self, from: Data(contentsOf: url))
  #expect(saved.milestones.map { $0.title } == ["Planned", "InProg", "Done", "Unknown", "Dropped"])
}

@Test("Agenda normalize: backlog title/id sorting")
func agendaNormalizeBacklog() throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  let slug = "norm-backlog"
  let url = tmp.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agenda.triad.json")
  try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

  let backlog: [BacklogItem] = [
    BacklogItem(title: "Zeta"),
    BacklogItem(title: "Alpha", slug: "a"),
    BacklogItem(title: "Beta", slug: "b"),
  ]
  let doc = AgendaDoc(
    slug: slug,
    title: "Agenda",
    updated: "2025-09-01T00:00:00Z",
    status: "active",
    agent: .init(role: slug),
    backlog: backlog
  )
  let enc = JSONEncoder()
  enc.outputFormatting = [.prettyPrinted, .sortedKeys]
  try enc.encode(doc).write(to: url)

  // Title sort
  _ = try AgendaNormalizeCore.apply(startingAt: tmp, slug: slug, write: true, backlogSort: .title)
  var saved = try JSONDecoder().decode(AgendaDoc.self, from: Data(contentsOf: url))
  #expect(saved.backlog.map { $0.title } == ["Alpha", "Beta", "Zeta"])

  // ID (slug) sort: Zeta has no slug -> last
  _ = try AgendaNormalizeCore.apply(startingAt: tmp, slug: slug, write: true, backlogSort: .id)
  saved = try JSONDecoder().decode(AgendaDoc.self, from: Data(contentsOf: url))
  #expect(saved.backlog.map { $0.slug ?? "" } == ["a", "b", ""])  // nil slug at end
}
