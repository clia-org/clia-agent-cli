import Foundation
import Testing

@testable import CLIAAgentAudit
@testable import CLIACoreModels

@Test
func localAuditPassesForWellFormedAgent() throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    "CLIAAgentAudit-\(UUID().uuidString)")
  defer { try? fm.removeItem(at: tmp) }
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)

  // Seed CLIA structure
  let cliaRoot = tmp.appendingPathComponent(".clia")
  let agentsRoot = cliaRoot.appendingPathComponent("agents")
  try fm.createDirectory(at: agentsRoot, withIntermediateDirectories: true)

  // Agent slug
  let slug = "ios-engineer"
  let agentDir = agentsRoot.appendingPathComponent(slug)
  try fm.createDirectory(at: agentDir, withIntermediateDirectories: true)

  // Mirrors (no placeholders; correct slug header)
  let agentMD = """
    # iOS Engineer Agent

    > Slug: `ios-engineer`
    """
  let agendaMD = "# iOS Engineer — Agenda\n"
  let agencyMD = "# iOS Engineer — Agency\n"
  try agentMD.write(
    to: agentDir.appendingPathComponent("\(slug).agent.triad.md"), atomically: true, encoding: .utf8)
  try agendaMD.write(
    to: agentDir.appendingPathComponent("\(slug).agenda.triad.md"), atomically: true, encoding: .utf8)
  try agencyMD.write(
    to: agentDir.appendingPathComponent("\(slug).agency.triad.md"), atomically: true, encoding: .utf8)

  // Triads (schema 0.2.0 defaults)
  let f = ISO8601DateFormatter()
  f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  let now = f.string(from: Date())

  let agent = AgentDoc(
    slug: slug,
    title: "iOS Engineer",
    updated: now,
    status: "draft",
    mentors: [],
    tags: [],
    links: [],
    purpose: "Safeguard iOS quality.",
    responsibilities: ["Ensure tests pass"],
    guardrails: ["Block release on red CI"],
    checklists: [],
    sections: [],
    notes: [],
    extensions: [:]
  )
  var agenda = AgendaDoc(
    slug: slug,
    title: "iOS Engineer",
    updated: now,
    status: "draft",
    agent: .init(role: slug)
  )
  // Add a notes block so json-notes passes
  agenda.notes = [Note(blocks: [NoteBlock(kind: "list", text: ["Daily: review CI"])])]
  let agency = AgencyDoc(slug: slug, title: "iOS Engineer", updated: now, status: "draft")

  let enc = JSONEncoder()
  enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
  try Data(enc.encode(agent)).write(
    to: agentDir.appendingPathComponent("\(slug)@Repo.\(slug).agent.triad.json"))
  try Data(enc.encode(agenda)).write(
    to: agentDir.appendingPathComponent("\(slug)@Repo.\(slug).agenda.triad.json"))
  try Data(enc.encode(agency)).write(
    to: agentDir.appendingPathComponent("\(slug)@Repo.\(slug).agency.triad.json"))

  // Roster entry
  let roster = """
    # Agents

    | Agent | Mission | Location |
    | ----- | ------- | -------- |
    | iOS Engineer | Safeguard iOS quality. | `.clia/agents/ios-engineer/` |
    """
  try roster.write(to: tmp.appendingPathComponent("AGENTS.md"), atomically: true, encoding: .utf8)

  // Run audit
  let result = try CLIAAgentAudit.auditAgents(at: tmp)
  let ids = Set(result.checks.map { $0.id })

  #expect(ids.contains("clia-stack"))
  #expect(ids.contains("agents-stack"))
  #expect(ids.contains("agents-roster"))
  #expect(ids.contains("agent-ios-engineer-files"))
  #expect(ids.contains("agent-ios-engineer-placeholders"))
  #expect(ids.contains("agent-ios-engineer-json"))
  #expect(ids.contains("agent-ios-engineer-json-core"))
  #expect(ids.contains("agent-ios-engineer-json-notes"))
  #expect(ids.contains("agent-ios-engineer-roster"))

  // Ensure key checks pass
  func status(_ id: String) -> String? {
    result.checks.first { $0.id == id }.map { String(describing: $0.status) }
  }
  #expect(status("clia-stack") == "pass")
  #expect(status("agents-stack") == "pass")
  #expect(status("agents-roster") == "pass")
  #expect(status("agent-ios-engineer-files") == "pass")
  #expect(status("agent-ios-engineer-placeholders") == "pass")
  #expect(status("agent-ios-engineer-json") == "pass")
  #expect(status("agent-ios-engineer-json-core") == "pass")
  #expect(status("agent-ios-engineer-json-notes") == "pass")
  #expect(status("agent-ios-engineer-roster") == "pass")
}
