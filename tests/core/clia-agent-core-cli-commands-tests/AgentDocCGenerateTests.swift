import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands
@testable import CLIACoreModels

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@Test("Agent DocC generate: writes generated bundle from memory sources")
func agentDocCGenerateWritesGeneratedBundle() throws {
  let root = try makeTemporaryRepoRoot()
  let slug = "carrie"

  let agentDir = root.appendingPathComponent(".clia/agents/\(slug)", isDirectory: true)
  let assetsDir = agentDir.appendingPathComponent("assets", isDirectory: true)
  try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

  let avatarURL = assetsDir.appendingPathComponent("avatar-pixel.png")
  try "avatar".write(to: avatarURL, atomically: true, encoding: .utf8)

  _ = try writeAgentDoc(at: root, slug: slug, avatarPath: avatarURL)
  _ = try writeAgendaDoc(at: root, slug: slug)
  _ = try writeAgencyDoc(at: root, slug: slug)

  let doccRoot = agentDir.appendingPathComponent("docc", isDirectory: true)
  let memoryDocc = doccRoot.appendingPathComponent("memory.docc", isDirectory: true)
  let expertiseDocc = memoryDocc.appendingPathComponent("expertise", isDirectory: true)
  let journalDocc = memoryDocc.appendingPathComponent("journal", isDirectory: true)

  let expertiseResources = expertiseDocc.appendingPathComponent("resources", isDirectory: true)
  let expertiseArticles = expertiseDocc.appendingPathComponent("articles", isDirectory: true)
  try FileManager.default.createDirectory(
    at: expertiseResources, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(
    at: expertiseArticles, withIntermediateDirectories: true)

  let heroBanner = expertiseResources.appendingPathComponent("hero-expertise-banner.svg")
  let iconResource = expertiseResources.appendingPathComponent("icon-test.svg")
  let paletteCSS = expertiseResources.appendingPathComponent("carrie.docc.css")
  try "<svg></svg>".write(to: heroBanner, atomically: true, encoding: .utf8)
  try "<svg></svg>".write(to: iconResource, atomically: true, encoding: .utf8)
  try "body {}".write(to: paletteCSS, atomically: true, encoding: .utf8)

  let themeSettings = expertiseDocc.appendingPathComponent("theme-settings.json")
  try """
  {
    "meta": {
      "paletteCss": "resources/carrie.docc.css"
    }
  }
  """.write(to: themeSettings, atomically: true, encoding: .utf8)

  let memoryRoot = memoryDocc.appendingPathComponent("memory.md")
  try """
  # Carrie Memory

  @Metadata {
    @TechnologyRoot
  }
  """.write(to: memoryRoot, atomically: true, encoding: .utf8)

  let expertiseRoot = expertiseDocc.appendingPathComponent("carrie-expertise.md")
  try """
  # Carrie Expertise

  @Metadata {
    @TechnologyRoot
    @PageImage(purpose: card, source: "hero-expertise-banner", alt: "Hero")
  }

  @Image(source: "icon-test", alt: "Icon")
  """.write(to: expertiseRoot, atomically: true, encoding: .utf8)

  let expertiseArticle = expertiseArticles.appendingPathComponent("docc-sample.md")
  try """
  # DocC Sample

  @Image(source: "icon-test", alt: "Icon")
  """.write(to: expertiseArticle, atomically: true, encoding: .utf8)

  let journalArticles = journalDocc.appendingPathComponent("articles", isDirectory: true)
  try FileManager.default.createDirectory(
    at: journalArticles, withIntermediateDirectories: true)

  let journalRoot = journalDocc.appendingPathComponent("carrie-journal.md")
  try """
  # Carrie Journal

  - <doc:journal-2025-12-21>
  """.write(to: journalRoot, atomically: true, encoding: .utf8)

  let journalEntry = journalArticles.appendingPathComponent("journal-2025-12-21.md")
  try """
  # Journal 2025-12-21
  """.write(to: journalEntry, atomically: true, encoding: .utf8)

  var command = try AgentDocCCommandGroup.Generate.parseAsRoot([
    "--slug", slug,
    "--path", root.path,
    "--write",
  ])
  try command.run()

  let generatedDocc = agentDir.appendingPathComponent("docc/generated.docc", isDirectory: true)

  let generatedRoot = generatedDocc.appendingPathComponent("triads/\(slug)-agent.md")
  #expect(FileManager.default.fileExists(atPath: generatedRoot.path))

  let generatedMemoryRoot = generatedDocc.appendingPathComponent("memory/memory.md")
  #expect(FileManager.default.fileExists(atPath: generatedMemoryRoot.path))

  let generatedExpertise =
    generatedDocc
    .appendingPathComponent("memory/expertise/carrie-expertise.md")
  let generatedExpertiseText = try String(contentsOf: generatedExpertise, encoding: .utf8)
  #expect(generatedExpertiseText.contains("@TechnologyRoot"))

  let generatedSTypeOverview =
    generatedDocc
    .appendingPathComponent("s-type/articles/\(slug)-s-type-overview.md")
  #expect(FileManager.default.fileExists(atPath: generatedSTypeOverview.path))

  let generatedAvatar = generatedDocc.appendingPathComponent("resources/avatar.png")
  #expect(FileManager.default.fileExists(atPath: generatedAvatar.path))
}

@Test("Agent DocC generate: warns and skips when memory bundle missing")
func agentDocCGenerateWarnsWhenMemoryMissing() throws {
  let root = try makeTemporaryRepoRoot()
  let slug = "missing-memory"
  _ = try writeAgentDoc(at: root, slug: slug, avatarPath: makeAvatar(at: root, slug: slug))
  _ = try writeAgendaDoc(at: root, slug: slug)
  _ = try writeAgencyDoc(at: root, slug: slug)

  // DocC directory exists but memory bundle is absent.
  let doccRoot = root.appendingPathComponent(".clia/agents/\(slug)/docc", isDirectory: true)
  try FileManager.default.createDirectory(at: doccRoot, withIntermediateDirectories: true)

  var command = try AgentDocCCommandGroup.Generate.parseAsRoot([
    "--slug", slug,
    "--path", root.path,
    "--write",
  ])

  let output = try captureStdout {
    try command.run()
  }

  #expect(output.contains("Memory bundle missing"))

  let generatedDocc = doccRoot.appendingPathComponent("generated.docc", isDirectory: true)
  #expect(!FileManager.default.fileExists(atPath: generatedDocc.path))
}

@Test("Agent DocC generate: warns before replacing existing generated bundle")
func agentDocCGenerateWarnsBeforeReplacingGenerated() throws {
  let root = try makeTemporaryRepoRoot()
  let slug = "replace-generated"
  _ = try writeAgentDoc(at: root, slug: slug, avatarPath: makeAvatar(at: root, slug: slug))
  _ = try writeAgendaDoc(at: root, slug: slug)
  _ = try writeAgencyDoc(at: root, slug: slug)

  // Minimal memory bundle to allow generation.
  try writeMinimalMemoryBundle(at: root, slug: slug)

  let doccRoot = root.appendingPathComponent(".clia/agents/\(slug)/docc", isDirectory: true)
  let generatedDocc = doccRoot.appendingPathComponent("generated.docc", isDirectory: true)
  try FileManager.default.createDirectory(at: generatedDocc, withIntermediateDirectories: true)

  var command = try AgentDocCCommandGroup.Generate.parseAsRoot([
    "--slug", slug,
    "--path", root.path,
    "--write",
  ])

  let output = try captureStdout {
    try command.run()
  }

  #expect(output.contains("Replacing existing generated bundle"))
  // Generation should still succeed and recreate the bundle.
  let generatedMemoryRoot = generatedDocc.appendingPathComponent("memory/memory.md")
  #expect(FileManager.default.fileExists(atPath: generatedMemoryRoot.path))
}

private func makeTemporaryRepoRoot() throws -> URL {
  let fileManager = FileManager.default
  let root = fileManager.temporaryDirectory.appendingPathComponent(
    UUID().uuidString, isDirectory: true)
  try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
  try fileManager.createDirectory(
    at: root.appendingPathComponent(".clia"), withIntermediateDirectories: true)
  return root
}

private func writeAgentDoc(at root: URL, slug: String, avatarPath: URL) throws -> URL {
  let fileManager = FileManager.default
  let agentURL = root.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agent.json")
  try fileManager.createDirectory(
    at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)

  let doc = AgentDoc(
    slug: slug,
    title: slug,
    updated: "2025-12-21T00:00:00Z",
    status: "active",
    role: "Documentation Steward",
    avatarPath: ".clia/agents/\(slug)/assets/\(avatarPath.lastPathComponent)"
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(doc).write(to: agentURL)
  return agentURL
}

private func makeAvatar(at root: URL, slug: String) throws -> URL {
  let assetsDir = root.appendingPathComponent(".clia/agents/\(slug)/assets", isDirectory: true)
  try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
  let avatarURL = assetsDir.appendingPathComponent("avatar.png")
  try "avatar".write(to: avatarURL, atomically: true, encoding: .utf8)
  return avatarURL
}

private func writeAgendaDoc(at root: URL, slug: String) throws -> URL {
  let fileManager = FileManager.default
  let agendaURL = root.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agenda.json")
  try fileManager.createDirectory(
    at: agendaURL.deletingLastPathComponent(), withIntermediateDirectories: true)

  let nextSection = Section(title: "Next", slug: "next", kind: "list", items: ["Ship"])
  let doc = AgendaDoc(
    slug: slug,
    title: slug,
    updated: "2025-12-21T00:00:00Z",
    status: "active",
    agent: .init(role: slug),
    sections: [nextSection]
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(doc).write(to: agendaURL)
  return agendaURL
}

private func writeAgencyDoc(at root: URL, slug: String) throws -> URL {
  let fileManager = FileManager.default
  let agencyURL = root.appendingPathComponent(".clia/agents/\(slug)/\(slug)@sample.agency.json")
  try fileManager.createDirectory(
    at: agencyURL.deletingLastPathComponent(), withIntermediateDirectories: true)

  let doc = AgencyDoc(
    slug: slug,
    title: slug,
    updated: "2025-12-21T00:00:00Z",
    status: "active",
    entries: []
  )
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  try encoder.encode(doc).write(to: agencyURL)
  return agencyURL
}

private func writeMinimalMemoryBundle(at root: URL, slug: String) throws {
  let doccRoot = root.appendingPathComponent(".clia/agents/\(slug)/docc", isDirectory: true)
  let memoryDocc = doccRoot.appendingPathComponent("memory.docc", isDirectory: true)
  let expertiseDocc = memoryDocc.appendingPathComponent("expertise", isDirectory: true)
  let journalDocc = memoryDocc.appendingPathComponent("journal", isDirectory: true)
  let expertiseResources = expertiseDocc.appendingPathComponent("resources", isDirectory: true)
  let expertiseArticles = expertiseDocc.appendingPathComponent("articles", isDirectory: true)
  try FileManager.default.createDirectory(
    at: expertiseResources, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(
    at: expertiseArticles, withIntermediateDirectories: true)

  let heroBanner = expertiseResources.appendingPathComponent("hero-expertise-banner.svg")
  try "<svg></svg>".write(to: heroBanner, atomically: true, encoding: .utf8)
  let expertiseRoot = expertiseDocc.appendingPathComponent("\(slug)-expertise.md")
  try """
  # \(slug.capitalized) Expertise

  @Metadata { @TechnologyRoot }
  """.write(to: expertiseRoot, atomically: true, encoding: .utf8)
  let expertiseArticle = expertiseArticles.appendingPathComponent("sample.md")
  try "# Sample".write(to: expertiseArticle, atomically: true, encoding: .utf8)

  let journalArticles = journalDocc.appendingPathComponent("articles", isDirectory: true)
  try FileManager.default.createDirectory(
    at: journalArticles, withIntermediateDirectories: true)
  let journalRoot = journalDocc.appendingPathComponent("\(slug)-journal.md")
  try "# Journal".write(to: journalRoot, atomically: true, encoding: .utf8)
  let journalEntry = journalArticles.appendingPathComponent("journal-2025-12-21.md")
  try "# Entry".write(to: journalEntry, atomically: true, encoding: .utf8)
}

private func captureStdout(_ body: () throws -> Void) rethrows -> String {
  let original = dup(STDOUT_FILENO)
  let pipeFds = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
  defer {
    pipeFds.deallocate()
  }
  guard pipe(pipeFds) == 0 else { return "" }
  dup2(pipeFds[1], STDOUT_FILENO)
  close(pipeFds[1])
  var output = Data()
  try body()
  var buffer = [UInt8](repeating: 0, count: 1024)
  while true {
    let count = read(pipeFds[0], &buffer, buffer.count)
    if count <= 0 { break }
    output.append(buffer, count: count)
  }
  dup2(original, STDOUT_FILENO)
  close(original)
  close(pipeFds[0])
  return String(data: output, encoding: .utf8) ?? ""
}
