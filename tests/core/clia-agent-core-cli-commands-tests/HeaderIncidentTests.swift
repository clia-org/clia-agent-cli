import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

@Test("ConversationHeader adds incident on line 3 when active.json exists")
func testHeaderIncludesIncident() throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: tmp) }

  // Create a repo root marker
  try "# AGENCY\n".data(using: .utf8)!.write(to: tmp.appendingPathComponent("AGENCY.md"))

  // Write active incident banner
  let incidentDir = tmp.appendingPathComponent(".clia/incidents")
  try fm.createDirectory(at: incidentDir, withIntermediateDirectories: true)
  let active = incidentDir.appendingPathComponent("active.json")
  let payload: [String: Any] = [
    "id": "test-incident",
    "title": "Test Incident",
    "severity": "S1",
    "status": "active",
    "owner": "patch",
    "started": ISO8601DateFormatter().string(from: Date()),
  ]
  let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
  try data.write(to: active)

  // Write minimal workspace.clia.json with header config. Path: .clia/workspace.clia.json
  let wrk = tmp.appendingPathComponent(".clia")
  try fm.createDirectory(at: wrk, withIntermediateDirectories: true)
  let wsURL = wrk.appendingPathComponent("workspace.clia.json")
  let ws: [String: Any] = [
    "schemaVersion": "0.4.0",
    "header": [
      "defaults": [
        "mode": "planning",
        "title": "Status",
        "attendeeEmojis": "🧭💡",
        "attendees": ["codex@sample", "rismay@sample"],
      ],
      "rendering": [
        "templates": [
          "line1": "[🧭: %{mode}] [💡| {title}]",
          "line2": "[{attendeeEmojis}| {attendees}]",
        ],
        "attendeesFormat": "{role} (^{slug})",
        "delimiter": " · ",
      ],
    ],
  ]
  try JSONSerialization.data(withJSONObject: ws, options: [.prettyPrinted]).write(to: wsURL)

  let config = try WorkspaceConfig.load(under: tmp)
  #expect(config.header != nil)

  // Render header (no triads required; workspace header drives content)
  let lines = ConversationHeader.render(slug: "codex", under: tmp)
  let h = try #require(lines)
  #expect(!h.line1.isEmpty)
  #expect(!h.line2.isEmpty)
  #expect(h.line3 == "[INCIDENT — S1 — Test Incident]")
}
