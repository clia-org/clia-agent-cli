import Foundation
import Testing

@testable import CLIACoreModels

@Suite("Triad decoding")
struct TriadDecodingTests {
  @Test
  func decodeAgentDoc() throws {
    let json = """
      {
        "schemaVersion": "0.4.0",
        "slug": "codex",
        "title": "Codex Utility Agent",
        "updated": "2025-09-29T12:00:00Z",
        "status": "draft",
        "role": "tool",
        "mentors": [],
        "tags": [],
        "links": [],
        "responsibilities": [],
        "guardrails": [],
        "checklists": [],
        "sections": [],
        "notes": [],
        "emojiTags": ["🔧"],
        "contributionMix": {
          "primary": [
            { "type": "tool", "weight": 3 },
            { "type": "code", "weight": 2 }
          ],
          "secondary": [
            { "type": "review", "weight": 1 }
          ]
        }
      }
      """.data(using: .utf8)!
    let doc = try JSONDecoder().decode(AgentDoc.self, from: json)
    #expect(doc.slug == "codex")
    #expect(doc.title.contains("Codex"))
    #expect(doc.role == "tool")
    let mix = try #require(doc.contributionMix)
    #expect(mix.primary.first?.type == "tool")
    #expect(mix.secondary?.first?.type == "review")
    // responseHeader moved to workspace.clia.json; agent docs no longer carry header
  }

  @Test
  func decodeAgentDoc_rejectsLegacySchema() async {
    let legacy = """
      {
        "schemaVersion": "0.3.0",
        "slug": "legacy",
        "title": "Legacy Agent",
        "updated": "2024-01-01T00:00:00Z",
        "status": "draft",
        "role": "tool",
        "mentors": [],
        "tags": [],
        "links": [],
        "responsibilities": [],
        "guardrails": [],
        "checklists": [],
        "sections": [],
        "notes": []
      }
      """.data(using: .utf8)!
    #expect(throws: DecodingError.self, "schemaVersion 0.3.0 should be rejected") {
      _ = try JSONDecoder().decode(AgentDoc.self, from: legacy)
    }
  }

  @Test
  func decodeAgencyDoc() throws {
    let json = """
      {
        "schemaVersion": "0.4.0",
        "slug": "codex",
        "title": "Codex Utility Agent Agency",
        "updated": "2025-09-29T12:00:00Z",
        "mentors": [],
        "tags": [],
        "links": [],
        "entries": [
          {
            "timestamp": "2025-09-29T12:00:00Z",
            "title": "Note",
            "contributions": [
              {
                "by": "codex",
                "types": [
                  { "type": "doc", "weight": 1, "evidence": "PR #1" }
                ]
              }
            ]
          }
        ],
        "sections": [],
        "notes": []
      }
      """.data(using: .utf8)!
    let doc = try JSONDecoder().decode(AgencyDoc.self, from: json)
    #expect(doc.entries.count == 1)
  }

  @Test
  func agendaDocDefaults() throws {
    let now = "2025-09-29T12:00:00Z"
    let doc = AgendaDoc(slug: "codex", title: "Agenda", updated: now, agent: .init(role: "codex"))
    #expect(doc.schemaVersion == "0.4.0")
    #expect(doc.notes.isEmpty)
  }
}
