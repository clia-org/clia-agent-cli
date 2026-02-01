import Foundation
import Testing

@testable import CLIAAgentCore

@Suite("Mirrors render Focus domains when present")
struct MirrorsFocusDomainsTests {
  @Test
  func rendersFocusDomains() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: fm.currentDirectoryPath)
      .appendingPathComponent(".clia/tmp/mirrors-focus-\(UUID().uuidString)")
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tmp) }

    let agentsRoot = tmp.appendingPathComponent(".clia/agents")
    let agentDir = agentsRoot.appendingPathComponent("demo")
    try fm.createDirectory(at: agentDir, withIntermediateDirectories: true)

    let triad = agentDir.appendingPathComponent("demo@sample.agent.json")
    let json: [String: Any] = [
      "schemaVersion": "0.4.0",
      "slug": "demo",
      "title": "Demo",
      "updated": "2025-10-03T00:00:00Z",
      "role": "Demo Engineer",
      "focusDomains": [
        ["label": "Platform iOS Engineer", "identifier": "ios-platform", "weight": 3],
        ["label": "Tau app UI Designer", "identifier": "tau-app-ui", "weight": 2],
        ["label": "DocC infra", "identifier": "docc-infra"],
      ],
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    try data.write(to: triad)

    let outputs = try MirrorRenderer.mirrorAgents(at: agentsRoot, dryRun: false)
    #expect(!outputs.isEmpty)

    let out = agentDir.appendingPathComponent(".generated/demo.agent.triad.md")
    #expect(fm.fileExists(atPath: out.path))
    let md = try String(contentsOf: out, encoding: .utf8)

    #expect(md.contains("## Focus domains"))
    #expect(md.contains("Platform iOS Engineer (#ios-platform)"))
    #expect(md.contains("Tau app UI Designer (#tau-app-ui)"))
    #expect(md.contains("DocC infra (#docc-infra)"))
  }
}
