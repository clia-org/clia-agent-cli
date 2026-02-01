import Foundation
import Testing

@testable import CLIAAgentCore

@Suite("Mirrors render Contribution mix when present")
struct MirrorsContributionMixTests {
  @Test
  func rendersContributionMixSections() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: fm.currentDirectoryPath)
      .appendingPathComponent(".clia/tmp/mirrors-mix-\(UUID().uuidString)")
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tmp) }

    // Agents root with one agent
    let agentsRoot = tmp.appendingPathComponent(".clia/agents")
    let agentDir = agentsRoot.appendingPathComponent("demo")
    try fm.createDirectory(at: agentDir, withIntermediateDirectories: true)

    // Minimal agent triad with contributionMix
    let triad = agentDir.appendingPathComponent("demo@sample.agent.json")
    let json: [String: Any] = [
      "schemaVersion": "0.3.2",
      "slug": "demo",
      "title": "Demo",
      "updated": "2025-10-03T00:00:00Z",
      "role": "Demo Engineer",
      "contributionMix": [
        "primary": [
          ["type": "code", "weight": 5],
          ["type": "design", "weight": 2],
          ["type": "doc", "weight": 1],
        ],
        "secondary": [
          ["type": "test", "weight": 2]
        ],
      ],
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    try data.write(to: triad)

    // Act: render mirrors
    let outputs = try MirrorRenderer.mirrorAgents(at: agentsRoot, dryRun: false)
    #expect(!outputs.isEmpty)

    let out = agentDir.appendingPathComponent(".generated/demo.agent.triad.md")
    #expect(fm.fileExists(atPath: out.path))
    let md = try String(contentsOf: out, encoding: .utf8)

    // Assert: sections and representative lines exist
    #expect(md.contains("## Contribution mix"))
    #expect(md.contains("### Primary"))
    #expect(md.contains("code=5"))
    #expect(md.contains("design=2"))
    #expect(md.contains("doc=1"))
    #expect(md.contains("### Secondary"))
    #expect(md.contains("test=2"))
  }
}
