import CLIACoreModels
import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("Roster report surfaces missing types and per-segment coverage")
func testRosterReportSegments() throws {
  let fm = FileManager.default
  let tmpRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
    UUID().uuidString)
  try fm.createDirectory(at: tmpRoot, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: tmpRoot) }

  // Mark repo root (AGENTS.md acts as a root indicator for other utilities)
  try "# roster test\n".data(using: .utf8)!.write(to: tmpRoot.appendingPathComponent("AGENTS.md"))

  // Root agent: cameron (code + doc)
  let rootAgents = tmpRoot.appendingPathComponent(".clia/agents/cameron")
  try fm.createDirectory(at: rootAgents, withIntermediateDirectories: true)
  let cameron = AgentDoc(
    slug: "cameron",
    title: "Cameron",
    updated: ISO8601DateFormatter().string(from: Date()),
    mentors: [],
    tags: [],
    links: [],
    responsibilities: [],
    guardrails: [],
    checklists: [],
    sections: [],
    notes: [],
    contributionMix: ContributionMix(
      primary: [
        .init(type: "doc", weight: 2),
        .init(type: "code", weight: 1),
      ],
      secondary: [
        .init(type: "ideas", weight: 1)
      ]
    )
  )
  let enc = JSONEncoder()
  enc.outputFormatting = [.prettyPrinted, .sortedKeys]
  try enc.encode(cameron).write(
    to: rootAgents.appendingPathComponent("cameron@sample.agent.json"))

  // Submodule agent: tau (app + tool)
  let sampleRoot = tmpRoot.appendingPathComponent("code/sample")
  try fm.createDirectory(at: sampleRoot, withIntermediateDirectories: true)
  let sampleAgents = sampleRoot.appendingPathComponent(".clia/agents/tau")
  try fm.createDirectory(at: monoAgents, withIntermediateDirectories: true)
  let tau = AgentDoc(
    slug: "tau",
    title: "Tau",
    updated: ISO8601DateFormatter().string(from: Date()),
    mentors: [],
    tags: [],
    links: [],
    responsibilities: [],
    guardrails: [],
    checklists: [],
    sections: [],
    notes: [],
    contributionMix: ContributionMix(
      primary: [
        .init(type: "app", weight: 1),
        .init(type: "tool", weight: 1),
        .init(type: "platform", weight: 1),
      ]
    )
  )
  try enc.encode(tau).write(
    to: sampleAgents.appendingPathComponent("tau@sample.agent.json"))

  // Advertise the submodule so the command scans it
  let gitmodules = """
    [submodule "sample"]
    \tpath = code/sample
    \turl = git@example.com:sample.git
    """
  try gitmodules.data(using: .utf8)!.write(to: tmpRoot.appendingPathComponent(".gitmodules"))

  let report = try buildRosterReport(root: tmpRoot)

  #expect(report.overallTypes["code"]?.contains("cameron") == true)
  #expect(report.overallTypes["app"]?.contains("tau") == true)
  #expect(report.missingTypes.contains("bug"))
  #expect(!report.missingTypes.contains("code"))

  let rootSegment = try #require(report.segments.first(where: { $0.label == "root" }))
  #expect(rootSegment.types["code"]?.contains("cameron") == true)
  #expect(rootSegment.missingTypes.contains("app"))

  let monoSegment = try #require(report.segments.first(where: { $0.label == "code/sample" }))
  #expect(monoSegment.types["app"]?.contains("tau") == true)
  #expect(monoSegment.missingTypes.contains("doc"))
  #expect(!monoSegment.missingTypes.contains("app"))

  // Text rendering includes segment headers and missing type summary
  let text = renderRosterText(report: report)
  #expect(text.contains("Missing types (overall)"))
  #expect(text.contains("Segment code/sample"))
  #expect(text.contains("📖 doc (1, Σ=0.67)"))
  #expect(text.contains("💻 code (1, Σ=0.33)"))
  #expect(text.contains("🤔 ideas (1, Σ₂=1.00)"))

  // JSON rendering exposes combined + segment detail
  let jsonString = try renderRosterJSON(report: report)
  let data = jsonString.data(using: .utf8)!
  let payload = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
  let missing = try #require(payload["missingTypes"] as? [String])
  #expect(missing.contains("bug"))
  #expect(!missing.contains("code"))

  let emojis = try #require(payload["emojis"] as? [String: String])
  #expect(emojis["doc"] == "📖")
  #expect(emojis["code"] == "💻")

  let shares = try #require(payload["primaryShares"] as? [String: Double])
  let docShare = try #require(shares["doc"])
  let codeShare = try #require(shares["code"])
  #expect((docShare - 0.667).magnitude < 0.001)
  #expect((codeShare - 0.333).magnitude < 0.001)

  let secondary = try #require(payload["secondaryShares"] as? [String: Double])
  let ideasShare = try #require(secondary["ideas"])
  #expect((ideasShare - 1.0).magnitude < 0.001)

  let segments = try #require(payload["segments"] as? [[String: Any]])
  let monoJSON = try #require(segments.first(where: { ($0["label"] as? String) == "code/sample" }))
  let monoMissing = try #require(monoJSON["missingTypes"] as? [String])
  #expect(monoMissing.contains("doc"))
  let rootJSON = try #require(segments.first(where: { ($0["label"] as? String) == "root" }))
  let rootSecondary = try #require(rootJSON["secondaryShares"] as? [String: Double])
  let rootIdeas = try #require(rootSecondary["ideas"])
  #expect((rootIdeas - 1.0).magnitude < 0.001)
}
