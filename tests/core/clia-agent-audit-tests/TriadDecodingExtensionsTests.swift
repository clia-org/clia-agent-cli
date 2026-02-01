import Foundation
import Testing

@testable import CLIACoreModels

@Suite("Triad decoding — extensions and unknowns")
struct TriadDecodingExtensionsTests {
  @Test
  func decodeAgentDoc_withExtensionsAndNotes() throws {
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
        "emojiTags": [],
        "contributionMix": {
          "primary": [
            { "type": "doc", "weight": 2 }
          ],
          "secondary": [
            { "type": "ideas", "weight": 1 }
          ]
        },
        "notes": [ { "author": "cli", "timestamp": "2025-09-29T00:00:00Z", "blocks": [ { "kind": \
      "md", "text": ["hello"] } ] } ],
        "extensions": {
          "truth": true,
          "rank": 0.5,
          "tags": ["a", "b"]
        },
        "unknownKey": "ignored"
      }
      """.data(using: .utf8)!

    let doc = try JSONDecoder().decode(AgentDoc.self, from: json)
    #expect(doc.slug == "codex")
    let mix = try #require(doc.contributionMix)
    #expect(mix.primary.first?.type == "doc")
    #expect(mix.secondary?.first?.type == "ideas")
    // Notes array decoded
    #expect(doc.notes.count == 1)
    #expect(doc.notes.first?.author == "cli")
    #expect(doc.notes.first?.blocks.first?.text.first == "hello")
    // Extensions map decoded with mixed types
    let ex = doc.extensions ?? [:]
    if case .bool(let b)? = ex["truth"] { #expect(b == true) } else { #expect(Bool(false)) }
    if case .number(let n)? = ex["rank"] { #expect(n == 0.5) } else { #expect(Bool(false)) }
    if case .array(let arr)? = ex["tags"] { #expect(arr.count == 2) } else { #expect(Bool(false)) }
    // Top-level display role decoded
    #expect(doc.role == "tool")
  }

  @Test
  func decodeAgencyDoc_entryExtensions() throws {
    let json = """
      {
        "schemaVersion": "0.4.0",
        "slug": "codex",
        "title": "Agency",
        "updated": "2025-09-29T12:00:00Z",
        "mentors": [],
        "tags": [],
        "links": [],
        "entries": [
          {
            "timestamp": "2025-09-29T12:34:56Z",
            "title": "Note",
            "summary": "S",
            "contributions": [
              {
                "by": "codex",
                "types": [ { "type": "doc", "weight": 1, "evidence": "PR #1" } ]
              }
            ],
            "extensions": { "hint": "x" }
          }
        ],
        "sections": [],
        "notes": []
      }
      """.data(using: .utf8)!
    let doc = try JSONDecoder().decode(AgencyDoc.self, from: json)
    #expect(doc.entries.count == 1)
    if case .string(let s)? = doc.entries[0].extensions?["hint"] {
      #expect(s == "x")
    } else {
      #expect(Bool(false))
    }
  }

  @Test
  func decodeAgendaDoc_unknownFieldsIgnored() throws {
    let json = """
      {
        "schemaVersion": "0.4.0",
        "slug": "codex",
        "title": "Agenda",
        "updated": "2025-09-29T12:00:00Z",
        "agent": { "role": "codex", "scope": null, "lLevel": null },
        "mentors": [],
        "tags": [],
        "links": [],
        "principles": ["Type safety"],
        "themes": [],
        "horizons": [],
        "initiatives": [],
        "milestones": [],
        "backlog": [],
        "dependencies": [],
        "risks": [],
        "sections": [],
        "notes": [],
        "unknown": { "x": 1 }
      }
      """.data(using: .utf8)!
    let doc = try JSONDecoder().decode(AgendaDoc.self, from: json)
    #expect(doc.agent.role == "codex")
    #expect(doc.principles == ["Type safety"])
  }
}
