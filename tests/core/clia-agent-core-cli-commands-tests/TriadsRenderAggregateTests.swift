import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@Test("Triads render: writes agenda mirror")
func triadsRenderWritesAgendaMirror() throws {
  let root = try makeTemporaryRepoRoot()
  let slug = "render-agenda-test"
  _ = try writeAgentDoc(at: root, slug: slug, title: "Render Agenda")
  _ = try writeAgendaDoc(at: root, slug: slug, title: "Render Agenda")

  var command = try TriadsCommandGroup.Render.parseAsRoot([
    "--kind", "agenda",
    "--slug", slug,
    "--path", root.path,
    "--write",
  ])
  try command.run()

  let outputURL = root.appendingPathComponent(".clia/agents/\(slug)/.generated/\(slug).agenda.triad.md")
  #expect(FileManager.default.fileExists(atPath: outputURL.path))
  let contents = try String(contentsOf: outputURL, encoding: .utf8)
  #expect(contents.contains("# Render Agenda — Agenda"))
}

@Test("Triads render: writes agent mirror")
func triadsRenderWritesAgentMirror() throws {
  let root = try makeTemporaryRepoRoot()
  let slug = "render-agent-test"
  _ = try writeAgentDoc(at: root, slug: slug, title: "Render Agent")

  var command = try TriadsCommandGroup.Render.parseAsRoot([
    "--kind", "agent",
    "--slug", slug,
    "--path", root.path,
    "--write",
  ])
  try command.run()

  let outputURL = root.appendingPathComponent(".clia/agents/\(slug)/.generated/\(slug).agent.triad.md")
  #expect(FileManager.default.fileExists(atPath: outputURL.path))
  let contents = try String(contentsOf: outputURL, encoding: .utf8)
  #expect(contents.contains("# Render Agent — Agent Profile"))
}

@Test("Triads render: writes agency mirror")
func triadsRenderWritesAgencyMirror() throws {
  let root = try makeTemporaryRepoRoot()
  let slug = "render-agency-test"
  _ = try writeAgentDoc(at: root, slug: slug, title: "Render Agency")
  _ = try writeAgencyDoc(at: root, slug: slug, title: "Render Agency")

  var command = try TriadsCommandGroup.Render.parseAsRoot([
    "--kind", "agency",
    "--slug", slug,
    "--path", root.path,
    "--write",
  ])
  try command.run()

  let outputURL = root.appendingPathComponent(".clia/agents/\(slug)/.generated/\(slug).agency.triad.md")
  #expect(FileManager.default.fileExists(atPath: outputURL.path))
  let contents = try String(contentsOf: outputURL, encoding: .utf8)
  #expect(contents.contains("# Render Agency — Agency"))
}

@Test("Triads aggregate: emits JSON with agenda entries")
func triadsAggregateEmitsJson() throws {
  let root = try makeTemporaryRepoRoot()
  let firstSlug = "aggregate-first"
  let secondSlug = "aggregate-second"
  _ = try writeAgendaDoc(at: root, slug: firstSlug, title: "First Agenda")
  _ = try writeAgendaDoc(at: root, slug: secondSlug, title: "Second Agenda")

  var command = try TriadsCommandGroup.Aggregate.parseAsRoot([
    "--kind", "agenda",
    "--root", root.path,
    "--format", "json",
  ])

  let output = try captureStdout {
    try command.run()
  }
  let data = try #require(output.data(using: .utf8))
  let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
  let agents = obj?["agents"] as? [[String: Any]]
  let slugs = agents?.compactMap { $0["agent"] as? String } ?? []
  #expect(slugs.contains(firstSlug))
  #expect(slugs.contains(secondSlug))
}

private func makeTemporaryRepoRoot() throws -> URL {
  let fileManager = FileManager.default
  let root = fileManager.temporaryDirectory.appendingPathComponent(
    UUID().uuidString, isDirectory: true)
  try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
  try fileManager.createDirectory(
    at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
  return root
}

private func writeAgendaDoc(at root: URL, slug: String, title: String) throws -> URL {
  let fileManager = FileManager.default
  let agendaURL = root.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agenda.triad.json")
  try fileManager.createDirectory(
    at: agendaURL.deletingLastPathComponent(), withIntermediateDirectories: true)

  let nextSection = Section(title: "Next", slug: "next", kind: "list", items: ["Ship updates"])
  let backlog = [BacklogItem(title: "Later", slug: "later")]
  let doc = AgendaDoc(
    slug: slug,
    title: title,
    updated: "2025-12-21T00:00:00Z",
    status: "active",
    agent: .init(role: slug),
    backlog: backlog,
    sections: [nextSection]
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(doc).write(to: agendaURL)
  return agendaURL
}

private func writeAgentDoc(at root: URL, slug: String, title: String) throws -> URL {
  let fileManager = FileManager.default
  let agentURL = root.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agent.triad.json")
  try fileManager.createDirectory(
    at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)

  let doc = AgentDoc(
    slug: slug,
    title: title,
    updated: "2025-12-21T00:00:00Z",
    status: "active",
    role: "Doc Steward"
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(doc).write(to: agentURL)
  return agentURL
}

private func writeAgencyDoc(at root: URL, slug: String, title: String) throws -> URL {
  let fileManager = FileManager.default
  let agencyURL = root.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agency.triad.json")
  try fileManager.createDirectory(
    at: agencyURL.deletingLastPathComponent(), withIntermediateDirectories: true)

  let doc = AgencyDoc(
    slug: slug,
    title: title,
    updated: "2025-12-21T00:00:00Z",
    status: "active",
    entries: []
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(doc).write(to: agencyURL)
  return agencyURL
}

private func captureStdout(_ body: () throws -> Void) rethrows -> String {
  let originalStdout = dup(STDOUT_FILENO)
  let pipe = Pipe()
  dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
  defer {
    fflush(stdout)
    dup2(originalStdout, STDOUT_FILENO)
    close(originalStdout)
  }
  try body()
  pipe.fileHandleForWriting.closeFile()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return String(data: data, encoding: .utf8) ?? ""
}
