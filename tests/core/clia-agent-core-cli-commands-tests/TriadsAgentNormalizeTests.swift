import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

@Test("Agent normalize: links and operationModes sorting")
func agentNormalizeLinksAndModes() throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  let slug = "norm-agent"
  let url = tmp.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agent.json")
  try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

  let links: [LinkRef] = [
    LinkRef(title: "zeta", url: "https://b"),
    LinkRef(title: "alpha", url: "https://c"),
    LinkRef(title: nil, url: "https://a"),
    LinkRef(title: "alpha", url: "https://b"),
  ]

  var exts: [String: ExtensionValue] = [:]
  exts["operationModes"] = .array([.string("real-world"), .string("edge"), .string("cloud")])

  let doc = AgentDoc(
    slug: slug,
    title: "Agent",
    updated: "2025-09-01T00:00:00Z",
    status: "active",
    role: slug,
    links: links,
    extensions: exts
  )
  let enc = JSONEncoder()
  enc.outputFormatting = [.prettyPrinted, .sortedKeys]
  try enc.encode(doc).write(to: url)

  _ = try AgentNormalizeCore.apply(startingAt: tmp, slug: slug, write: true)

  let saved = try JSONDecoder().decode(AgentDoc.self, from: Data(contentsOf: url))
  // Links sorted by title asc (alpha before zeta); tie-break on URL; nil title last
  let linkOrder = saved.links.map { "\($0.title ?? "")|\($0.url ?? "")" }
  #expect(
    linkOrder == [
      "alpha|https://b",
      "alpha|https://c",
      "zeta|https://b",
      "|https://a",
    ])

  if let ext = saved.extensions, case .array(let vals)? = ext["operationModes"] {
    let modes = vals.compactMap { v -> String? in
      guard case .string(let s) = v else { return nil }
      return s
    }
    #expect(modes == ["cloud", "edge", "real-world"])  // sorted asc
  } else {
    Issue.record("operationModes not present or not an array")
  }
}

@Test("Agent normalize: canonical rewrite when formatting differs")
func agentNormalizeCanonicalRewrite() throws {
  let fm = FileManager.default
  let tmp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  try fm.createDirectory(at: tmp.appendingPathComponent(".git"), withIntermediateDirectories: true)

  let slug = "norm-agent-canon"
  let url = tmp.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agent.json")
  try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

  // Write non-canonical JSON (no pretty print, unsorted keys)
  let doc = AgentDoc(
    slug: slug,
    title: "Agent",
    updated: "2025-09-01T00:00:00Z",
    role: slug,
    links: [LinkRef(title: "alpha", url: "https://b")]
  )
  let plain = JSONEncoder()  // default formatting (non-canonical)
  try plain.encode(doc).write(to: url)

  // First pass should detect byte diff and write canonical
  let res1 = try AgentNormalizeCore.apply(startingAt: tmp, slug: slug, write: true)
  #expect(res1.changed)

  // Second pass should find no changes (already canonical)
  let res2 = try AgentNormalizeCore.apply(startingAt: tmp, slug: slug, write: true)
  #expect(!res2.changed)
}
