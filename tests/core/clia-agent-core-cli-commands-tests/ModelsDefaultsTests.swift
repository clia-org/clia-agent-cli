import Foundation
import Testing

@testable import CLIACoreModels

@Suite("Core Models Defaults")
struct ModelsDefaultsTests {
  @Test
  func agentDoc_defaults() throws {
    let now = "2025-09-30T12:00:00Z"
    let doc = AgentDoc(slug: "codex", title: "Agent", updated: now, role: "codex")
    #expect(doc.schemaVersion == "0.4.0")
    #expect(doc.notes.isEmpty)
  }

  @Test
  func agendaDoc_defaults() throws {
    let now = "2025-09-30T12:00:00Z"
    let doc = AgendaDoc(slug: "codex", title: "Agenda", updated: now, agent: .init(role: "codex"))
    #expect(doc.schemaVersion == "0.4.0")
    #expect(doc.notes.isEmpty)
  }

  @Test
  func agencyDoc_defaults() throws {
    let now = "2025-09-30T12:00:00Z"
    let doc = AgencyDoc(slug: "codex", title: "Agency", updated: now)
    #expect(doc.schemaVersion == "0.4.0")
    #expect(doc.entries.isEmpty)
    #expect(doc.notes.isEmpty)
  }
}
