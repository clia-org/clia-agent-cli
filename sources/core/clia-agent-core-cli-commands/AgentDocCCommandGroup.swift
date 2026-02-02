import ArgumentParser
import CLIAAgentCore
import CLIACore
import CLIACoreModels
import Foundation
import SwiftFigletKit

public struct AgentDocCCommandGroup: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "agent-docc",
      abstract: "Generate agent DocC bundles (profile + memory)",
      subcommands: [Generate.self]
    )
  }

  public init() {}
}

extension AgentDocCCommandGroup {
  public struct Generate: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(
        commandName: "generate",
        abstract: "Generate generated.docc + memory.docc bundles for an agent"
      )
    }

    @Option(name: .customLong("slug"), help: "Agent slug")
    public var slug: String

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    public var path: String?

    @Option(
      name: .customLong("generated-bundle"),
      help: "Generated bundle directory name (default: generated.docc)")
    public var generatedBundle: String = "generated.docc"

    @Option(
      name: .customLong("memory-bundle"),
      help: "Memory bundle directory name (default: memory.docc)")
    public var memoryBundle: String = "memory.docc"

    @Flag(name: .customLong("write"), help: "Write bundles (default: dry run)")
    public var write: Bool = false

    @Flag(name: .customLong("merged"), help: "Use merged triads across lineage when rendering")
    public var merged: Bool = false

    @Flag(
      name: .customLong("include-launchpad-docc"), inversion: .prefixedNo,
      help: "Include .docc bundles found under spm/launchpad")
    public var includeLaunchpadDocc: Bool = true

    public init() {}

    public func run() throws {
      let fileManager = FileManager.default
      let workingRoot = URL(fileURLWithPath: path ?? fileManager.currentDirectoryPath)
      let normalizedSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalizedSlug.isEmpty else { throw ValidationError("--slug is required") }

      let normalizedGeneratedBundle = generatedBundle.lowercased()
      let normalizedMemoryBundle = memoryBundle.lowercased()
      guard normalizedGeneratedBundle != normalizedMemoryBundle else {
        throw ValidationError("--generated-bundle and --memory-bundle must be distinct")
      }

      let context = try resolveAgentContext(for: normalizedSlug, under: workingRoot)
      let agentDir = context.dir
      let doccRoot = agentDir.appendingPathComponent("docc", isDirectory: true)
      guard fileManager.fileExists(atPath: doccRoot.path) else {
        throw ValidationError("DocC directory not found: \(doccRoot.path)")
      }

      let memoryDocc = doccRoot.appendingPathComponent(memoryBundle, isDirectory: true)
      let expertiseDocc = memoryDocc.appendingPathComponent("expertise", isDirectory: true)
      let journalDocc = memoryDocc.appendingPathComponent("journal", isDirectory: true)
      let resourcesResolution = resolveDirectoryLowercasedPreferred(named: "resources", in: memoryDocc)
      guard let memoryResourcesDir = resourcesResolution.url else {
        print(
          "warning: Memory resources missing, skipping DocC generation: "
            + memoryDocc.appendingPathComponent("resources", isDirectory: true).path
        )
        return
      }
      if resourcesResolution.foundUppercase {
        print(
          "warning: Found 'Resources' directory; prefer lowercase 'resources' for memory bundle: "
            + memoryDocc.appendingPathComponent("Resources", isDirectory: true).path
        )
      }

      if !fileManager.fileExists(atPath: memoryDocc.path) {
        print("warning: Memory bundle missing, skipping DocC generation: \(memoryDocc.path)")
        return
      }

      let generatedDocc = doccRoot.appendingPathComponent(generatedBundle, isDirectory: true)
      let memoryOutput = generatedDocc.appendingPathComponent("memory", isDirectory: true)
      guard fileManager.fileExists(atPath: expertiseDocc.path) else {
        print("warning: Expertise bundle missing, skipping DocC generation: \(expertiseDocc.path)")
        return
      }
      guard fileManager.fileExists(atPath: journalDocc.path) else {
        print("warning: Journal bundle missing, skipping DocC generation: \(journalDocc.path)")
        return
      }

      // New conventions:
      // - No articles/ subfolders.
      // - Expertise/journal roots are plain index pages (no @TechnologyRoot).
      // - Memory root is memory.docc/index.md (sole @TechnologyRoot).
      let expertiseRoot = try findIndexMarkdown(
        in: expertiseDocc,
        preferredFileNames: ["\(normalizedSlug)-expertise.md", "expertise.md"]
      )
      let journalRoot = try findIndexMarkdown(
        in: journalDocc,
        preferredFileNames: ["\(normalizedSlug)-journal.md", "journal.md"]
      )

      let allExpertiseMarkdown = try listMarkdownFiles(in: expertiseDocc)
      let expertiseArticles = allExpertiseMarkdown.filter { $0 != expertiseRoot }

      let allJournalMarkdown = try listMarkdownFiles(in: journalDocc)
      let journalArticles = allJournalMarkdown.filter { $0 != journalRoot }

      var triadFiles = try resolveTriadFiles(in: agentDir)
      var agentDoc = try loadAgentDoc(from: triadFiles.agentURL)

      let repoRoot = findRepoRoot(startingAt: workingRoot) ?? workingRoot
      // Optional: switch to merged views (across lineage) for profile + triad rendering
      if merged {
        // Compute merged views
        let mergedAgent = Merger.mergeAgent(slug: normalizedSlug, under: repoRoot)
        let mergedAgenda = Merger.mergeAgenda(slug: normalizedSlug, under: repoRoot)
        let mergedAgency = Merger.mergeAgency(slug: normalizedSlug, under: repoRoot)

        // Synthesize an AgentDoc from merged fields to reuse existing rendering helpers
        agentDoc = AgentDoc(
          schemaVersion: mergedAgent.schemaVersion,
          slug: mergedAgent.slug,
          title: mergedAgent.title,
          updated: mergedAgent.updated,
          status: mergedAgent.status,
          role: mergedAgent.role,
          inherits: nil,
          sourcePath: nil,
          avatarPath: mergedAgent.avatarPath,
          figletFontName: mergedAgent.figletFontName,
          mentors: mergedAgent.mentors,
          tags: mergedAgent.tags,
          links: mergedAgent.links,
          purpose: mergedAgent.purpose,
          responsibilities: mergedAgent.responsibilities,
          guardrails: mergedAgent.guardrails,
          checklists: [],
          sections: [],
          notes: mergedAgent.notes,
          extensions: mergedAgent.extensions,
          emojiTags: mergedAgent.emojiTags,
          contributionMix: mergedAgent.contributionMix,
          focusDomains: nil,
          persona: mergedAgent.persona,
          systemInstructions: mergedAgent.systemInstructions,
          cliSpec: mergedAgent.cliSpec
        )

        // Emit temporary merged triad JSON files so we can reuse MirrorRenderer
        let tmpRoot = FileManager.default.temporaryDirectory
          .appendingPathComponent(
            "clia-agent-docc-merged-\(normalizedSlug)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpRoot, withIntermediateDirectories: true)
        let mergedAgentURL = tmpRoot.appendingPathComponent("\(normalizedSlug).agent.triad.json")
        let mergedAgendaURL = tmpRoot.appendingPathComponent("\(normalizedSlug).agenda.triad.json")
        let mergedAgencyURL = tmpRoot.appendingPathComponent("\(normalizedSlug).agency.triad.json")
        try writeJSON(mergedAgent, to: mergedAgentURL)
        try writeJSON(mergedAgenda, to: mergedAgendaURL)
        try writeJSON(mergedAgency, to: mergedAgencyURL)
        triadFiles = .init(
          agentURL: mergedAgentURL, agendaURL: mergedAgendaURL, agencyURL: mergedAgencyURL)
      }

      let avatarSource = try resolveAvatarURL(
        from: agentDoc, slug: normalizedSlug, repoRoot: repoRoot)
      let figletFontName = resolveFigletFontName(from: agentDoc)
      let figletText = agentDoc.title.trimmingCharacters(in: .whitespacesAndNewlines)
      let figletBanner = renderFigletBanner(
        text: figletText.isEmpty ? normalizedSlug : figletText,
        fontName: figletFontName
      )
      let reveries = try loadReveries(from: agentDoc, repoRoot: repoRoot)

      let heroBannerURL = memoryResourcesDir.appendingPathComponent("hero-expertise-banner.svg")
      guard fileManager.fileExists(atPath: heroBannerURL.path) else {
        throw ValidationError("Hero banner missing: \(heroBannerURL.path)")
      }

      // Use stable, bundle-local avatar names so resources are easy to reference
      // and do not duplicate the slug or original filename. Preserve the file
      // extension to avoid format conversions.
      let generatedAvatarName = avatarSource.map { url -> String in
        let ext = url.pathExtension
        return ext.isEmpty ? "avatar" : "avatar.\(ext)"
      }
      let memoryAvatarName = avatarSource.map { url -> String in
        let ext = url.pathExtension
        return ext.isEmpty ? "memory-avatar" : "memory-avatar.\(ext)"
      }

      let memoryResourceMappings = try resourceMappings(
        in: memoryResourcesDir, prefix: "memory-")

      if write {
        if fileManager.fileExists(atPath: generatedDocc.path) {
          print("warning: Replacing existing generated bundle (will delete then recreate): \(generatedDocc.path)")
        }
        try resetDirectory(generatedDocc)
      }

      var outputs: [URL] = []

      try generateGeneratedBundle(
        slug: normalizedSlug,
        agentDoc: agentDoc,
        figletBanner: figletBanner,
        reveries: reveries,
        triadFiles: triadFiles,
        generatedDocc: generatedDocc,
        expertiseRoot: expertiseRoot,
        journalRoot: journalRoot,
        expertiseArticles: expertiseArticles,
        journalArticles: journalArticles,
        expertiseResourcesDir: memoryResourcesDir,
        themeSettings: memoryResourcesDir.appendingPathComponent("theme-settings.json"),
        avatarSource: avatarSource,
        avatarName: generatedAvatarName,
        heroBannerBase: heroBannerURL.deletingPathExtension().lastPathComponent,
        write: write,
        outputs: &outputs
      )

      try generateMemoryBundle(
        slug: normalizedSlug,
        agentDoc: agentDoc,
        figletBanner: figletBanner,
        reveries: reveries,
        memoryDocc: memoryOutput,
        expertiseRoot: expertiseRoot,
        journalRoot: journalRoot,
        expertiseArticles: expertiseArticles,
        journalArticles: journalArticles,
        expertiseResourcesDir: memoryResourcesDir,
        themeSettings: memoryResourcesDir.appendingPathComponent("theme-settings.json"),
        avatarSource: avatarSource,
        avatarName: memoryAvatarName,
        resourceMappings: memoryResourceMappings,
        write: write,
        outputs: &outputs
      )

      if includeLaunchpadDocc {
        let launchpadBundles = findLaunchpadDoccBundles(under: agentDir)
        try copyLaunchpadDoccBundles(
          launchpadBundles,
          into: generatedDocc.appendingPathComponent("launchpad", isDirectory: true),
          write: write,
          outputs: &outputs
        )
      }

      if write {
        for url in outputs { print(url.path) }
      } else {
        for url in outputs { print("would write \(url.path)") }
      }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
      let enc = JSONEncoder()
      enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      let data = try enc.encode(value)
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try data.write(to: url, options: .atomic)
    }

    private func resolveAgentContext(for slug: String, under root: URL) throws -> ContextItem {
      let contexts = LineageResolver.findAgentDirs(for: slug, under: root)
      guard let context = contexts.last else {
        throw ValidationError("No agent directory for slug=\(slug) found in lineage")
      }
      return context
    }

    private func resolveTriadFiles(in agentDir: URL) throws -> TriadFiles {
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: agentDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      guard
        let agentURL = files.first(where: {
          $0.lastPathComponent.hasSuffix(".agent.triad.json")
            && !$0.lastPathComponent.contains(".agency.")
        })
      else {
        throw ValidationError("Missing *.agent.triad.json in \(agentDir.path)")
      }
      guard let agendaURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agenda.triad.json") })
      else {
        throw ValidationError("Missing *.agenda.triad.json in \(agentDir.path)")
      }
      guard let agencyURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agency.triad.json") })
      else {
        throw ValidationError("Missing *.agency.triad.json in \(agentDir.path)")
      }
      return TriadFiles(agentURL: agentURL, agendaURL: agendaURL, agencyURL: agencyURL)
    }

    private func loadAgentDoc(from url: URL) throws -> AgentDoc {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(AgentDoc.self, from: data)
    }

    private func resolveAvatarURL(from doc: AgentDoc, slug: String, repoRoot: URL) throws -> URL? {
      if let path = doc.avatarPath?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
        let url: URL
        if path.hasPrefix("/") || path.contains("://") {
          url = URL(fileURLWithPath: path)
        } else if path.hasPrefix(".clia/") || path.hasPrefix("./.clia/") {
          // Treat .clia/* as repo-relative even when the current lineage context is agent-local.
          let trimmed = path.hasPrefix("./") ? String(path.dropFirst(2)) : path
          let effectiveRepoRoot = (repoRoot.lastPathComponent == ".clia")
            ? repoRoot.deletingLastPathComponent()
            : repoRoot
          url = effectiveRepoRoot.appendingPathComponent(trimmed)
        } else {
          // Treat as agent-local relative path.
          url = repoRoot.appendingPathComponent(path)
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
          throw ValidationError("Avatar path missing on disk: \(url.path)")
        }
        return url
      }

      let assetsDir = repoRoot.appendingPathComponent(
        ".clia/agents/\(slug)/assets", isDirectory: true)
      let candidates = [
        "\(slug).avatar.png",
        "\(slug).avatar.jpg",
        "\(slug).avatar.jpeg",
        "\(slug).avatar.svg",
        "avatar.png",
        "avatar.jpg",
        "avatar.jpeg",
        "avatar.svg",
      ]
      for fileName in candidates {
        let url = assetsDir.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) { return url }
      }

      return nil
    }

    private func findDocCRootMarkdown(in doccDir: URL) throws -> URL {
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: doccDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      let markdownFiles = files.filter { $0.pathExtension.lowercased() == "md" }
      let candidates = markdownFiles.filter { fileContainsTechnologyRoot($0) }
      if !candidates.isEmpty {
        return
          candidates
          .sorted { lhs, rhs in
            let lhsIsDocumentation = lhs.lastPathComponent.lowercased() == "documentation.md"
            let rhsIsDocumentation = rhs.lastPathComponent.lowercased() == "documentation.md"
            if lhsIsDocumentation != rhsIsDocumentation { return !lhsIsDocumentation }
            return lhs.lastPathComponent < rhs.lastPathComponent
          }
          .first!
      }
      guard let fallback = markdownFiles.first else {
        throw ValidationError("No root Markdown found in \(doccDir.path)")
      }
      return fallback
    }

    private func findJournalRootMarkdown(in doccDir: URL) throws -> URL {
      return try findDocCRootMarkdown(in: doccDir)
    }

    private func findIndexMarkdown(
      in doccDir: URL,
      preferredFileNames: [String]
    ) throws -> URL {
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: doccDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      let markdownFiles = files.filter { $0.pathExtension.lowercased() == "md" }
      for name in preferredFileNames {
        if let match = markdownFiles.first(where: { $0.lastPathComponent == name }) {
          return match
        }
      }
      // Fallback to the old heuristic.
      return try findDocCRootMarkdown(in: doccDir)
    }

    private func listMarkdownFiles(in directory: URL) throws -> [URL] {
      let fileManager = FileManager.default
      guard fileManager.fileExists(atPath: directory.path) else { return [] }
      let files = try fileManager.contentsOfDirectory(
        at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      return
        files
        .filter { $0.pathExtension.lowercased() == "md" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func resolveDirectoryLowercasedPreferred(
      named folder: String,
      in parent: URL
    ) -> (url: URL?, foundUppercase: Bool)
    {
      let fileManager = FileManager.default
      guard
        let contents = try? fileManager.contentsOfDirectory(
          at: parent, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
      else {
        return (nil, false)
      }

      let directories = contents.filter {
        (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
      }
      let lowerName = folder.lowercased()
      let capitalizedName = lowerName.prefix(1).uppercased() + lowerName.dropFirst()
      let lowerMatch = directories.first { $0.lastPathComponent == lowerName }
      let upperMatch = directories.first { $0.lastPathComponent == capitalizedName }
      let fallbackMatch = directories.first {
        $0.lastPathComponent.caseInsensitiveCompare(lowerName) == .orderedSame
      }

      let resolved = lowerMatch ?? upperMatch ?? fallbackMatch
      return (resolved, upperMatch != nil)
    }

    private func resourceMappings(in resourcesDir: URL, prefix: String) throws -> [ResourceMapping]
    {
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: resourcesDir, includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles])
      var mappings: [ResourceMapping] = []
      for url in files {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey])
        if values.isDirectory == true { continue }
        let originalName = url.lastPathComponent
        let originalBase = url.deletingPathExtension().lastPathComponent

        // Avoid double-prefixing files that already use the desired prefix.
        // Example: memory-avatar.svg should not become memory-memory-avatar.svg.
        if originalName.hasPrefix(prefix) || originalBase.hasPrefix(prefix) {
          continue
        }

        let newName = "\(prefix)\(originalName)"
        let newBase = "\(prefix)\(originalBase)"
        mappings.append(
          .init(
            originalFileName: originalName,
            newFileName: newName,
            originalBaseName: originalBase,
            newBaseName: newBase
          ))
      }
      return mappings.sorted { $0.originalFileName < $1.originalFileName }
    }

    private func findLaunchpadDoccBundles(under agentDir: URL) -> [URL] {
      let launchpadRoot = agentDir.appendingPathComponent("spm/launchpad", isDirectory: true)
      var bundles: [URL] = []
      guard let enumerator = FileManager.default.enumerator(
        at: launchpadRoot,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      ) else { return bundles }
      for case let url as URL in enumerator {
        if url.pathExtension.lowercased() == "docc" {
          bundles.append(url)
          enumerator.skipDescendants()
        }
      }
      return bundles.sorted { $0.path < $1.path }
    }

    private func copyLaunchpadDoccBundles(
      _ bundles: [URL],
      into destinationRoot: URL,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      guard !bundles.isEmpty else { return }
      let fm = FileManager.default
      if write {
        try fm.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
      }
      for src in bundles {
        let dest = destinationRoot.appendingPathComponent(src.lastPathComponent, isDirectory: true)
        if write {
          if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
          }
          try fm.copyItem(at: src, to: dest)
          outputs.append(dest)
        } else {
          outputs.append(dest)
        }
      }
    }

    private func generateGeneratedBundle(
      slug: String,
      agentDoc: AgentDoc,
      figletBanner: String?,
      reveries: ReveriesContent?,
      triadFiles: TriadFiles,
      generatedDocc: URL,
      expertiseRoot: URL,
      journalRoot: URL,
      expertiseArticles: [URL],
      journalArticles: [URL],
      expertiseResourcesDir: URL,
      themeSettings: URL,
      avatarSource: URL?,
      avatarName: String?,
      heroBannerBase: String,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      let generatedArticles = generatedDocc.appendingPathComponent("articles", isDirectory: true)
      let generatedResources = generatedDocc.appendingPathComponent("resources", isDirectory: true)

      let agentMarkdown = try MirrorRenderer.agentMarkdown(from: triadFiles.agentURL).markdown
      let agendaMarkdown = try MirrorRenderer.agendaMarkdown(from: triadFiles.agendaURL).markdown
      let agencyMarkdown = try MirrorRenderer.agencyMarkdown(from: triadFiles.agencyURL).markdown
      let triadDocs = TriadDocs(
        agentMarkdown: agentMarkdown,
        agendaMarkdown: agendaMarkdown,
        agencyMarkdown: agencyMarkdown
      )

      let agentHeading = "^\(slug): Agent Profile"
      let agendaHeading = "^\(slug): Agenda"
      let agencyHeading = "^\(slug): Agency"
      let agentDocContent = replaceFirstHeading(in: triadDocs.agentMarkdown, with: agentHeading)
      let agendaDocContent = replaceFirstHeading(in: triadDocs.agendaMarkdown, with: agendaHeading)
      let agencyDocContent = replaceFirstHeading(in: triadDocs.agencyMarkdown, with: agencyHeading)

      let agentArticle = generatedArticles.appendingPathComponent("\(slug)-agent-profile.md")
      let agendaArticle = generatedArticles.appendingPathComponent("\(slug)-agenda.triad.md")
      let agencyArticle = generatedArticles.appendingPathComponent("\(slug)-agency.triad.md")

      let expertiseRootName = expertiseRoot.lastPathComponent
      let journalRootName = "\(slug)-journal.md"

      let expertiseRootId = expertiseRoot.deletingPathExtension().lastPathComponent.lowercased()
      let journalRootId = journalRootName.replacingOccurrences(of: ".md", with: "")

      let expertiseDocIds =
        ([expertiseRootId]
        + expertiseArticles.map { $0.deletingPathExtension().lastPathComponent })
        .map { $0.lowercased() }
      let journalDocIds =
        ([journalRootId]
        + journalArticles.map { $0.deletingPathExtension().lastPathComponent })
        .map { $0.lowercased() }

      let contributorReferenceDocId = resolveContributorSystemDocId(from: expertiseDocIds)
      let filteredExpertiseDocIds = expertiseDocIds.filter { $0 != contributorReferenceDocId }

      let triadDocIds = [
        "\(slug)-agent-profile",
        "\(slug)-agenda.triad",
        "\(slug)-agency.triad",
      ]
      let aStarTriadsDocId = "\(slug)-a-star-triads"
      let sTypeContributionDocId = "\(slug)-s-type-contribution-system"
      let sTypeOverviewDocId = "\(slug)-s-type-overview"
      let sTypeScoringDocId = "\(slug)-s-type-scoring"

      let contributorLinks = [
        ContributorLink(heading: "A* Triads", docId: aStarTriadsDocId),
        ContributorLink(heading: "S-Type Contribution System", docId: sTypeContributionDocId),
      ]

      // Build a sectioned expertise index (by contributor type) for any agent
      let expertiseIndexDocId = "\(slug)-expertise-by-type"
      let expertiseIndexArticle =
        generatedArticles.appendingPathComponent("\(expertiseIndexDocId).md")
      // Build source map for metadata parsing
      var expertiseSourceMap: [String: URL] = [:]
      expertiseSourceMap[expertiseRootId] = expertiseRoot
      for u in expertiseArticles {
        expertiseSourceMap[u.deletingPathExtension().lastPathComponent.lowercased()] = u
      }

      var wroteByTypeIndex = false
      if let byTypeContent = try renderExpertiseByTypeIndex(
        slug: slug,
        agentDoc: agentDoc,
        expertiseDocIds: filteredExpertiseDocIds,
        sourceURLs: expertiseSourceMap,
        repoRoot: findRepoRoot(startingAt: generatedDocc) ?? generatedDocc
      ) {
        try writeText(byTypeContent, to: expertiseIndexArticle, write: write, outputs: &outputs)
        wroteByTypeIndex = true
      }

      let generatedRootName = "\(slug)-agent.md"
      let generatedRoot = generatedDocc.appendingPathComponent(generatedRootName)
      // Put the sectioned expertise index and expertise root under an Overview section
      var overviewDocIds: [String] = []
      if wroteByTypeIndex { overviewDocIds.append(expertiseIndexDocId) }
      overviewDocIds.append(expertiseRootId)

      // Heuristic categorization for curated Topics (bundle‑agnostic)
      func lc(_ s: String) -> String { s.lowercased() }
      var groupDocc: [String] = []
      var groupCliaNaming: [String] = []
      var groupPasskit: [String] = []
      var groupMigrations: [String] = []
      var groupTooling: [String] = []
      var groupTemplates: [String] = []

      for id in filteredExpertiseDocIds where !overviewDocIds.contains(id) {
        let s = lc(id)
        if s.contains("docc") || s.contains("palette") || s.contains("visual")
          || s.contains("renderer") || s.contains("interview") || s.contains("page-customization")
        {
          groupDocc.append(id)
          continue
        }
        if s.contains("passkit") {
          groupPasskit.append(id)
          continue
        }
        if s.contains("migration") || s.contains("structure-update") || s.contains("secrets") {
          groupMigrations.append(id)
          continue
        }
        if s.contains("common-process") || s.contains("command-spec") || s.contains("ci")
          || s.contains("tooling") || s.contains("tool")
        {
          groupTooling.append(id)
          continue
        }
        if s.contains("fix-template") || s.contains("motifs") {
          groupTemplates.append(id)
          continue
        }
        if s.contains("naming") || s.contains("root-rename") {
          groupCliaNaming.append(id)
          continue
        }
      }

      // Systems: generated contributor pages
      let groupSystems: [String] = [
        aStarTriadsDocId, sTypeContributionDocId, sTypeOverviewDocId, sTypeScoringDocId,
      ]

      // Roadmap & Journal
      let groupRoadmap: [String] = triadDocIds + [journalRootId]

      let rootContent = renderAgentProfileRoot(
        slug: slug,
        agentDoc: agentDoc,
        avatarBase: avatarName?.deletingPathExtensionName,
        heroBannerBase: heroBannerBase,
        figletBanner: figletBanner,
        reveries: reveries,
        triadDocIds: triadDocIds,
        contributorLinks: contributorLinks,
        overviewDocIds: overviewDocIds,
        expertiseDocIds: filteredExpertiseDocIds.filter { !overviewDocIds.contains($0) },
        journalDocIds: journalDocIds,
        grouped: CuratedGroups(
          docc: groupDocc,
          cliaNaming: groupCliaNaming,
          passkit: groupPasskit,
          migrations: groupMigrations,
          tooling: groupTooling,
          templates: groupTemplates,
          systems: groupSystems,
          roadmap: groupRoadmap)
      )

      let triadsDir = generatedDocc.appendingPathComponent("triads", isDirectory: true)
      let sTypeArticles = generatedDocc.appendingPathComponent("s-type/articles", isDirectory: true)
      let aStarTriadsArticle = triadsDir.appendingPathComponent("\(aStarTriadsDocId).md")
      let sTypeContributionArticle = sTypeArticles.appendingPathComponent(
        "\(sTypeContributionDocId).md")
      let sTypeOverviewArticle = sTypeArticles.appendingPathComponent("\(sTypeOverviewDocId).md")
      let sTypeScoringArticle = sTypeArticles.appendingPathComponent("\(sTypeScoringDocId).md")

      let aStarTriadsContent = renderAStarTriadsDoc(
        triadDocIds: triadDocIds,
        referenceDocId: contributorReferenceDocId
      )
      let sTypeContributionContent = renderSTypeContributionSystemDoc(
        overviewDocId: sTypeOverviewDocId,
        scoringDocId: sTypeScoringDocId,
        referenceDocId: contributorReferenceDocId
      )
      let sTypeOverviewContent = renderSTypeOverviewDoc(referenceDocId: contributorReferenceDocId)
      let sTypeScoringContent = renderSTypeScoringDoc(referenceDocId: contributorReferenceDocId)

      if write {
        try createDirectoryIfNeeded(generatedArticles)
        try createDirectoryIfNeeded(generatedResources)
        try createDirectoryIfNeeded(triadsDir)
        try createDirectoryIfNeeded(sTypeArticles)
      }

      try writeText(rootContent, to: generatedRoot, write: write, outputs: &outputs)
      try writeText(agentDocContent, to: agentArticle, write: write, outputs: &outputs)
      try writeText(agendaDocContent, to: agendaArticle, write: write, outputs: &outputs)
      try writeText(agencyDocContent, to: agencyArticle, write: write, outputs: &outputs)
      try writeText(aStarTriadsContent, to: aStarTriadsArticle, write: write, outputs: &outputs)
      try writeText(
        sTypeContributionContent,
        to: sTypeContributionArticle,
        write: write,
        outputs: &outputs
      )
      try writeText(sTypeOverviewContent, to: sTypeOverviewArticle, write: write, outputs: &outputs)
      try writeText(sTypeScoringContent, to: sTypeScoringArticle, write: write, outputs: &outputs)

      try copyRootMarkdown(
        from: expertiseRoot,
        to: generatedArticles.appendingPathComponent(expertiseRootName),
        shouldStripTechnologyRoot: true,
        write: write,
        outputs: &outputs
      )
      try copyJournalRoot(
        from: journalRoot,
        to: generatedArticles.appendingPathComponent(journalRootName),
        slug: slug,
        write: write,
        outputs: &outputs
      )

      try copyMarkdownFiles(
        expertiseArticles,
        to: generatedArticles,
        write: write,
        outputs: &outputs
      )
      try copyMarkdownFiles(
        journalArticles,
        to: generatedArticles,
        write: write,
        outputs: &outputs
      )

      try copyResources(
        from: expertiseResourcesDir,
        to: generatedResources,
        write: write,
        outputs: &outputs
      )

      if let avatarSource, let avatarName {
        let avatarDestination = generatedResources.appendingPathComponent(avatarName)
        try copyFile(avatarSource, to: avatarDestination, write: write, outputs: &outputs)
      }

      if FileManager.default.fileExists(atPath: themeSettings.path) {
        let dest = generatedDocc.appendingPathComponent(themeSettings.lastPathComponent)
        try copyFile(themeSettings, to: dest, write: write, outputs: &outputs)
      }

      // Triads mirror under generated.docc/triads
      let triadAgent = triadsDir.appendingPathComponent("\(slug)-agent.triad.md")
      try writeText(agentDocContent, to: triadAgent, write: write, outputs: &outputs)
    }

    private func generateMemoryBundle(
      slug: String,
      agentDoc: AgentDoc,
      figletBanner: String?,
      reveries: ReveriesContent?,
      memoryDocc: URL,
      expertiseRoot: URL,
      journalRoot: URL,
      expertiseArticles: [URL],
      journalArticles: [URL],
      expertiseResourcesDir: URL,
      themeSettings: URL,
      avatarSource: URL?,
      avatarName: String?,
      resourceMappings: [ResourceMapping],
      write: Bool,
      outputs: inout [URL]
    ) throws {
      let expertiseOutput = memoryDocc.appendingPathComponent("expertise", isDirectory: true)
      let journalOutput = memoryDocc.appendingPathComponent("journal", isDirectory: true)
      let memoryResources = memoryDocc.appendingPathComponent("resources", isDirectory: true)

      if write {
        try createDirectoryIfNeeded(expertiseOutput)
        try createDirectoryIfNeeded(journalOutput)
        try createDirectoryIfNeeded(memoryResources)
      }

      let expertiseRootName = expertiseRoot.lastPathComponent
      let journalRootName = "\(slug)-journal.md"

      let expertiseDocIds =
        ([expertiseRoot.deletingPathExtension().lastPathComponent]
        + expertiseArticles.map { $0.deletingPathExtension().lastPathComponent })
        .map { $0.lowercased() }
      let journalDocIds =
        ([journalRootName.replacingOccurrences(of: ".md", with: "")]
        + journalArticles.map { $0.deletingPathExtension().lastPathComponent })
        .map { $0.lowercased() }

      let avatarBase = avatarName?.deletingPathExtensionName
      let heroBannerBase = "memory-hero-expertise-banner"
      let memoryRootName = "index.md"
      let memoryRoot = memoryDocc.appendingPathComponent(memoryRootName)
      let rootContent = renderMemoryRoot(
        slug: slug,
        agentDoc: agentDoc,
        avatarBase: avatarBase,
        heroBannerBase: heroBannerBase,
        figletBanner: figletBanner,
        reveries: reveries,
        expertiseDocIds: expertiseDocIds,
        journalDocIds: journalDocIds
      )
      try writeText(rootContent, to: memoryRoot, write: write, outputs: &outputs)

      let expertiseContent = try String(contentsOf: expertiseRoot, encoding: .utf8)
      let remappedExpertise = applyResourceMappings(expertiseContent, mappings: resourceMappings)
      try writeText(
        remappedExpertise,
        to: expertiseOutput.appendingPathComponent(expertiseRootName),
        write: write,
        outputs: &outputs
      )

      let journalRootContent = try String(contentsOf: journalRoot, encoding: .utf8)
      let renamedJournalRoot = replaceFirstHeading(
        in: journalRootContent, with: "^\(slug): Journal")
      let remappedJournalRoot = applyResourceMappings(
        renamedJournalRoot, mappings: resourceMappings)
      try writeText(
        remappedJournalRoot,
        to: journalOutput.appendingPathComponent(journalRootName),
        write: write,
        outputs: &outputs
      )

      try copyMarkdownFiles(
        expertiseArticles,
        to: expertiseOutput,
        remapResources: resourceMappings,
        write: write,
        outputs: &outputs
      )
      try copyMarkdownFiles(
        journalArticles,
        to: journalOutput,
        remapResources: resourceMappings,
        write: write,
        outputs: &outputs
      )

      try copyResourcesWithMapping(
        from: expertiseResourcesDir,
        to: memoryResources,
        mappings: resourceMappings,
        write: write,
        outputs: &outputs
      )

      if let avatarSource, let avatarName {
        let avatarDestination = memoryResources.appendingPathComponent(avatarName)
        try copyFile(avatarSource, to: avatarDestination, write: write, outputs: &outputs)
      }

      if FileManager.default.fileExists(atPath: themeSettings.path) {
        let themeContent = try String(contentsOf: themeSettings, encoding: .utf8)
        let remappedTheme = applyResourceMappings(themeContent, mappings: resourceMappings)
        let dest = memoryResources.appendingPathComponent(themeSettings.lastPathComponent)
        try writeText(remappedTheme, to: dest, write: write, outputs: &outputs)
      }
    }

    private func createDirectoryIfNeeded(_ url: URL) throws {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func resetDirectory(_ url: URL) throws {
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: url.path) {
        try fileManager.removeItem(at: url)
      }
      try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func copyRootMarkdown(
      from source: URL,
      to destination: URL,
      shouldStripTechnologyRoot: Bool,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      let content = try String(contentsOf: source, encoding: .utf8)
      let stripped = shouldStripTechnologyRoot ? stripTechnologyRoot(from: content) : content
      try writeText(stripped, to: destination, write: write, outputs: &outputs)
    }

    private func copyJournalRoot(
      from source: URL,
      to destination: URL,
      slug: String,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      let content = try String(contentsOf: source, encoding: .utf8)
      let renamed = replaceFirstHeading(in: content, with: "^\(slug): Journal")
      try writeText(renamed, to: destination, write: write, outputs: &outputs)
    }

    private func copyMarkdownFiles(
      _ sources: [URL],
      to destinationDir: URL,
      remapResources: [ResourceMapping] = [],
      write: Bool,
      outputs: inout [URL]
    ) throws {
      for source in sources {
        let content = try String(contentsOf: source, encoding: .utf8)
        let remapped =
          remapResources.isEmpty
          ? content
          : applyResourceMappings(content, mappings: remapResources)
        let destination = destinationDir.appendingPathComponent(source.lastPathComponent)
        try writeText(remapped, to: destination, write: write, outputs: &outputs)
      }
    }

    private func copyResources(
      from sourceDir: URL,
      to destinationDir: URL,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(
        at: sourceDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
      for source in files {
        let values = try source.resourceValues(forKeys: [.isDirectoryKey])
        if values.isDirectory == true { continue }
        let destination = destinationDir.appendingPathComponent(source.lastPathComponent)
        try copyFile(source, to: destination, write: write, outputs: &outputs)
      }
    }

    private func copyResourcesWithMapping(
      from sourceDir: URL,
      to destinationDir: URL,
      mappings: [ResourceMapping],
      write: Bool,
      outputs: inout [URL]
    ) throws {
      for mapping in mappings {
        let source = sourceDir.appendingPathComponent(mapping.originalFileName)
        let destination = destinationDir.appendingPathComponent(mapping.newFileName)
        try copyFile(source, to: destination, write: write, outputs: &outputs)
      }
    }

    private func copyFile(
      _ source: URL,
      to destination: URL,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      outputs.append(destination)
      guard write else { return }
      let fileManager = FileManager.default
      try fileManager.createDirectory(
        at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }
      try fileManager.copyItem(at: source, to: destination)
    }

    private func writeText(
      _ content: String,
      to destination: URL,
      write: Bool,
      outputs: inout [URL]
    ) throws {
      outputs.append(destination)
      guard write else { return }
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
      try content.trimmingCharacters(in: .newlines).appending("\n")
        .write(to: destination, atomically: true, encoding: .utf8)
    }

    private func stripTechnologyRoot(from content: String) -> String {
      let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
      let filtered = lines.filter { !$0.contains("@TechnologyRoot") }
      return filtered.joined(separator: "\n")
    }

    private func replaceFirstHeading(in content: String, with heading: String) -> String {
      var lines = content.split(separator: "\n", omittingEmptySubsequences: false)
      for index in lines.indices {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("# ") {
          lines[index] = Substring("# \(heading)")
          return lines.joined(separator: "\n")
        }
      }
      lines.insert(Substring("# \(heading)"), at: 0)
      return lines.joined(separator: "\n")
    }

    private func applyResourceMappings(_ content: String, mappings: [ResourceMapping]) -> String {
      var updated = content
      for mapping in mappings {
        updated = updated.replacingOccurrences(
          of: "resources/\(mapping.originalFileName)",
          with: "resources/\(mapping.newFileName)")
        updated = updated.replacingOccurrences(
          of: "source: \"\(mapping.originalBaseName)\"",
          with: "source: \"\(mapping.newBaseName)\"")
      }
      return updated
    }

    private func fileContainsTechnologyRoot(_ url: URL) -> Bool {
      guard let content = try? String(contentsOf: url, encoding: .utf8) else { return false }
      return content.contains("@TechnologyRoot")
    }

    private struct ReveriesContent {
      let items: [String]
      let guidance: String?
    }

    private struct ContributorLink {
      let heading: String
      let docId: String
    }

    private func resolveFigletFontName(from doc: AgentDoc) -> String? {
      if let raw = doc.figletFontName {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
      }
      if let extensions = doc.extensions, case .string(let raw) = extensions["figletFontName"] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
      }
      return nil
    }

    private func renderFigletBanner(text: String, fontName: String?) -> String? {
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let fontName, !fontName.isEmpty, !trimmed.isEmpty else { return nil }
      let rendered =
        SFKRenderer.render(text: trimmed, fontName: fontName, color: .none) ?? trimmed
      let cleaned = rendered.trimmingCharacters(in: .newlines)
      return cleaned.isEmpty ? nil : cleaned
    }

    private func loadReveries(from doc: AgentDoc, repoRoot: URL) throws -> ReveriesContent? {
      guard
        let path = doc.persona?.reveriesPath?.trimmingCharacters(in: .whitespacesAndNewlines),
        !path.isEmpty
      else {
        return nil
      }
      let url =
        path.hasPrefix("/") || path.contains("://")
        ? URL(fileURLWithPath: path)
        : repoRoot.appendingPathComponent(path)
      guard FileManager.default.fileExists(atPath: url.path) else {
        throw ValidationError("Reveries path missing on disk: \(url.path)")
      }
      let content = try String(contentsOf: url, encoding: .utf8)
      return parseReveries(from: content)
    }

    private func parseReveries(from content: String) -> ReveriesContent? {
      var items: [String] = []
      var guidanceLines: [String] = []
      let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
      for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { continue }
        if trimmed.hasPrefix("# ") { continue }
        if trimmed.hasPrefix("- ") {
          items.append(String(trimmed.dropFirst(2)))
          continue
        }
        if trimmed.hasPrefix("Guidance:") {
          let note = trimmed.dropFirst("Guidance:".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
          if !note.isEmpty { guidanceLines.append(note) }
          continue
        }
        guidanceLines.append(trimmed)
      }
      if items.isEmpty && guidanceLines.isEmpty { return nil }
      let guidance =
        guidanceLines.isEmpty ? nil : guidanceLines.joined(separator: " ")
      return ReveriesContent(items: items, guidance: guidance)
    }

    private func renderFigletBlock(_ banner: String?) -> [String] {
      guard let banner else { return [] }
      let trimmed = banner.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return [] }
      var lines: [String] = []
      lines.append("```text")
      lines.append(
        contentsOf: trimmed.split(separator: "\n", omittingEmptySubsequences: false).map {
          String($0)
        })
      lines.append("```")
      lines.append("")
      return lines
    }

    private func renderCharacterSheet(from doc: AgentDoc) -> [String] {
      var rows: [(String, String)] = []
      if let role = doc.role?.trimmingCharacters(in: .whitespacesAndNewlines), !role.isEmpty {
        rows.append(("Role", role))
      }
      if let status = doc.status?.trimmingCharacters(in: .whitespacesAndNewlines), !status.isEmpty {
        rows.append(("Status", status))
      }
      if !doc.mentors.isEmpty {
        rows.append(("Mentors", doc.mentors.joined(separator: ", ")))
      }
      if let traits = formatTraits(from: doc) {
        rows.append(("Traits", traits))
      }
      if let domains = doc.focusDomains, !domains.isEmpty {
        rows.append(("Focus domains", formatFocusDomains(domains)))
      }
      guard !rows.isEmpty else { return [] }
      var lines: [String] = []
      lines.append("## Character sheet")
      lines.append("")
      lines.append("| Stat | Detail |")
      lines.append("| --- | --- |")
      for row in rows {
        let stat = escapeTableValue(row.0)
        let detail = escapeTableValue(row.1)
        lines.append("| \(stat) | \(detail) |")
      }
      lines.append("")
      return lines
    }

    private func formatTraits(from doc: AgentDoc) -> String? {
      let tags = doc.emojiTags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter {
        !$0.isEmpty
      }
      guard !tags.isEmpty else { return nil }
      if tags.count == 1, let label = resolveEmojiLabel(from: doc) {
        let tag = tags[0]
        if tag.rangeOfCharacter(from: .alphanumerics) == nil {
          return "\(tag) \(label)"
        }
      }
      return tags.joined(separator: " ")
    }

    private func resolveEmojiLabel(from doc: AgentDoc) -> String? {
      let candidates = doc.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter {
        !$0.isEmpty
      }
      guard let candidate = candidates.max(by: { $0.count < $1.count }) else { return nil }
      return titleCaseTag(candidate)
    }

    private func titleCaseTag(_ value: String) -> String {
      let words = value.replacingOccurrences(of: "-", with: " ").split(separator: " ")
      return words.map { word in
        let lower = word.lowercased()
        guard let first = lower.first else { return "" }
        return first.uppercased() + lower.dropFirst()
      }.joined(separator: " ")
    }

    private func renderReveriesSection(_ reveries: ReveriesContent) -> [String] {
      guard !reveries.items.isEmpty || reveries.guidance != nil else { return [] }
      var lines: [String] = []
      lines.append("## Reveries")
      lines.append("")
      lines.append("@TabNavigator {")
      if !reveries.items.isEmpty {
        for (index, item) in reveries.items.enumerated() {
          lines.append("  @Tab(\"Reverie \(index + 1)\") {")
          lines.append("    \(item)")
          lines.append("  }")
        }
      }
      lines.append("}")
      lines.append("")
      if let guidance = reveries.guidance, !guidance.isEmpty {
        lines.append("### Guidance")
        lines.append("")
        lines.append("> Note: \(guidance)")
        lines.append("")
      }
      return lines
    }

    private func renderAStarTriadsDoc(
      triadDocIds: [String],
      referenceDocId: String?
    ) -> String {
      var lines: [String] = []
      lines.append("# A* Triads")
      lines.append("")
      lines.append("A* Triads names the agent, agency, and agenda triads.")
      lines.append("")
      lines.append("## Topics")
      lines.append("")
      lines.append("### Triads")
      for docId in triadDocIds {
        let label = resolveTriadLabel(for: docId)
        lines.append("- [\(label)](<doc:\(docId)>)")
      }
      lines.append("")
      if let referenceDocId {
        lines.append("## References")
        lines.append("")
        lines.append("- <doc:\(referenceDocId)>")
        lines.append("")
      }
      return lines.joined(separator: "\n")
    }

    private func resolveTriadLabel(for docId: String) -> String {
      let lowercased = docId.lowercased()
      if lowercased.contains("agent-profile") { return "Agent" }
      if lowercased.contains("agenda") { return "Agenda" }
      if lowercased.contains("agency") { return "Agency" }
      return "Triad"
    }

    private func renderSTypeContributionSystemDoc(
      overviewDocId: String,
      scoringDocId: String,
      referenceDocId: String?
    ) -> String {
      var lines: [String] = []
      lines.append("# S-Type Contribution System")
      lines.append("")
      lines.append("S-Type defines a typed matrix for how contribution roles interact.")
      lines.append("")
      lines.append("## Topics")
      lines.append("")
      lines.append("### Core")
      lines.append("- <doc:\(overviewDocId)>")
      lines.append("- <doc:\(scoringDocId)>")
      lines.append("")
      if let referenceDocId {
        lines.append("## References")
        lines.append("")
        lines.append("- <doc:\(referenceDocId)>")
        lines.append("")
      }
      return lines.joined(separator: "\n")
    }

    private func renderSTypeOverviewDoc(referenceDocId: String?) -> String {
      var lines: [String] = []
      lines.append("# S-Type Contribution System: Overview")
      lines.append("")
      lines.append("S-Type defines contribution roles and a shared vocabulary for interactions.")
      lines.append("")
      if let referenceDocId {
        lines.append("## References")
        lines.append("")
        lines.append("- <doc:\(referenceDocId)>")
        lines.append("")
      }
      return lines.joined(separator: "\n")
    }

    private func renderSTypeScoringDoc(referenceDocId: String?) -> String {
      var lines: [String] = []
      lines.append("# S-Type Contribution System: Scoring")
      lines.append("")
      lines.append(
        "Scores are derived from deterministic signals like synergy, stability, and strain.")
      lines.append("")
      if let referenceDocId {
        lines.append("## References")
        lines.append("")
        lines.append("- <doc:\(referenceDocId)>")
        lines.append("")
      }
      return lines.joined(separator: "\n")
    }

    private func formatFocusDomains(_ domains: [FocusDomain]) -> String {
      let formatted = domains.map { domain in
        let label = domain.label.trimmingCharacters(in: .whitespacesAndNewlines)
        if let weight = domain.weight {
          return "\(label) (\(formatWeight(weight)))"
        }
        return label
      }
      return formatted.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func formatContributionMix(_ mix: ContributionMix) -> String {
      var parts: [String] = []
      let primary = mix.primary.map { formatContribution($0) }.filter { !$0.isEmpty }
      if !primary.isEmpty {
        parts.append("Primary: \(primary.joined(separator: ", "))")
      }
      if let secondary = mix.secondary {
        let formatted = secondary.map { formatContribution($0) }.filter { !$0.isEmpty }
        if !formatted.isEmpty {
          parts.append("Secondary: \(formatted.joined(separator: ", "))")
        }
      }
      return parts.joined(separator: " · ")
    }

    private func formatContribution(_ contribution: Contribution) -> String {
      let weight = formatWeight(contribution.weight)
      return weight.isEmpty ? contribution.type : "\(contribution.type) \(weight)"
    }

    private func escapeTableValue(_ value: String) -> String {
      value
        .replacingOccurrences(of: "|", with: "\\|")
        .replacingOccurrences(of: "\n", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formatWeight(_ weight: Double) -> String {
      if weight.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(weight)) }
      return String(weight)
    }

    private struct CuratedGroups {
      var docc: [String] = []
      var cliaNaming: [String] = []
      var passkit: [String] = []
      var migrations: [String] = []
      var tooling: [String] = []
      var templates: [String] = []
      var systems: [String] = []
      var roadmap: [String] = []
    }

    private func renderAgentProfileRoot(
      slug: String,
      agentDoc: AgentDoc,
      avatarBase: String?,
      heroBannerBase: String,
      figletBanner: String?,
      reveries: ReveriesContent?,
      triadDocIds: [String],
      contributorLinks: [ContributorLink],
      overviewDocIds: [String],
      expertiseDocIds: [String],
      journalDocIds: [String],
      grouped: CuratedGroups
    ) -> String {
      let purpose = agentDoc.purpose?.trimmingCharacters(in: .whitespacesAndNewlines)
      var lines: [String] = []
      lines.append("# ^\(slug): Agent Profile")
      lines.append("")
      lines.append("@Metadata {")
      lines.append("  @TechnologyRoot")
      lines.append("  @TitleHeading(\"^\(slug): Agent Profile\")")
      lines.append(
        "  @PageImage(purpose: card, source: \"\(heroBannerBase)\", alt: \"^\(slug) hero banner\")")
      lines.append("}")
      lines.append("")
      lines.append(contentsOf: renderFigletBlock(figletBanner))
      if let avatarBase {
        lines.append("@Image(source: \"\(avatarBase)\", alt: \"^\(slug) avatar\")")
        lines.append("")
      } else {
        lines.append("_Avatar placeholder._")
        lines.append("")
      }
      if let purpose, !purpose.isEmpty {
        lines.append("## Mission")
        lines.append("")
        lines.append(purpose)
        lines.append("")
      }
      lines.append(contentsOf: renderCharacterSheet(from: agentDoc))
      if let reveries {
        lines.append(contentsOf: renderReveriesSection(reveries))
      }
      lines.append("## Triads")
      lines.append("")
      for docId in triadDocIds {
        let label = resolveTriadLabel(for: docId)
        lines.append("- [\(label)](<doc:\(docId)>)")
      }
      lines.append("")
      if !contributorLinks.isEmpty {
        lines.append("## A* Triads & S-Type Contribution System")
        lines.append("")
        for link in contributorLinks {
          lines.append("- [\(link.heading)](<doc:\(link.docId)>)")
        }
        lines.append("")
      }
      lines.append("## Topics")
      lines.append("")
      if !overviewDocIds.isEmpty {
        lines.append("### Overview")
        for docId in overviewDocIds { lines.append("- <doc:\(docId)>") }
        lines.append("")
      }
      func section(_ title: String, _ items: [String]) {
        guard !items.isEmpty else { return }
        lines.append("### \(title)")
        for docId in items { lines.append("- <doc:\(docId)>") }
        lines.append("")
      }
      func uniquePreservingOrder(_ items: [String]) -> [String] {
        var seen: Set<String> = []
        var out: [String] = []
        out.reserveCapacity(items.count)
        for item in items where seen.insert(item).inserted {
          out.append(item)
        }
        return out
      }
      section("DocC", grouped.docc)
      section("CLIA & Naming", grouped.cliaNaming)
      section("PassKit", grouped.passkit)
      section("Migrations", grouped.migrations)
      section("Tooling", grouped.tooling)
      section("Templates", grouped.templates)
      section("Systems", grouped.systems)
      // Include any remaining expertise/journal items that weren’t matched
      let remainingExpertise = expertiseDocIds.filter {
        !(grouped.docc + grouped.cliaNaming + grouped.passkit + grouped.migrations + grouped.tooling
          + grouped.templates + grouped.systems + overviewDocIds).contains($0)
      }
      let remainingJournal = journalDocIds
      section("More", remainingExpertise)
      section("Roadmap & Journal", uniquePreservingOrder(grouped.roadmap + remainingJournal))
      lines.append("")
      return lines.joined(separator: "\n")
    }

    // MARK: Expertise index by contributor type
    private struct ContributorTypes: Decodable {
      struct Entry: Decodable {
        let title: String
        let emoji: String
        let synonyms: [String]?
      }
      let types: [String: Entry]
    }

    private func loadContributorTypes(root: URL) -> ContributorTypes? {
      let fm = FileManager.default
      // Prefer override under .clia/specs
      let override = root.appendingPathComponent(".clia/specs/all-contributors-types.v1.json")
      if fm.fileExists(atPath: override.path) {
        if let data = try? Data(contentsOf: override),
          let map = try? JSONDecoder().decode(ContributorTypes.self, from: data)
        {
          return map
        }
      }
      // Fallback to bundled resource
      if let url = Bundle.module.url(
        forResource: "all-contributors-types.v1", withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let map = try? JSONDecoder().decode(ContributorTypes.self, from: data)
      {
        return map
      }
      return nil
    }

    private func renderExpertiseByTypeIndex(
      slug: String,
      agentDoc: AgentDoc,
      expertiseDocIds: [String],
      sourceURLs: [String: URL],
      repoRoot: URL
    ) throws -> String? {
      guard let mix = agentDoc.contributionMix,
        !mix.primary.isEmpty || (mix.secondary?.isEmpty == false)
      else {
        return nil
      }
      guard let map = loadContributorTypes(root: repoRoot) else { return nil }
      // Build the type order: primary (by weight desc) then secondary
      struct OrderedType {
        let key: String
        let title: String
        let emoji: String
        let weight: Double
      }
      var ordered: [OrderedType] = []
      for c in mix.primary.sorted(by: { $0.weight > $1.weight }) {
        if let e = map.types[c.type] {
          ordered.append(.init(key: c.type, title: e.title, emoji: e.emoji, weight: c.weight))
        }
      }
      if let secondary = mix.secondary {
        for c in secondary {
          if let e = map.types[c.type] {
            ordered.append(.init(key: c.type, title: e.title, emoji: e.emoji, weight: c.weight))
          }
        }
      }
      // Assign docIDs to types using metadata/front matter only (no synonyms heuristic)
      var docsByType: [String: [String]] = [:]
      for docId in expertiseDocIds {
        if let url = sourceURLs[docId], let fmTypes = try? extractExpertiseTypes(from: url),
          !fmTypes.isEmpty
        {
          for t in fmTypes { docsByType[t, default: []].append(docId) }
        }
        // If not assigned, we intentionally leave the doc untyped so the
        // index only shows explicitly‑typed sections.
      }
      // If no types were matched at all, return nil so we don't create an empty index
      if docsByType.values.allSatisfy({ $0.isEmpty }) { return nil }
      // Render page
      var lines: [String] = []
      lines.append("# Expertise by contributor type")
      lines.append("")
      lines.append("@Metadata {")
      lines.append("  @TitleHeading(\"Expertise by contributor type\")")
      lines.append("  @PageColor(blue)")
      lines.append("}")
      lines.append("")
      lines.append(
        "This page groups ^\(slug) expertise articles by contributor roles declared in the agent triad."
      )
      lines.append("")
      // Legend (emoji chips), 3 columns per row
      let present = ordered.filter { docsByType[$0.key]?.isEmpty == false }
      if !present.isEmpty {
        lines.append("## Legend")
        var i = 0
        while i < present.count {
          lines.append("@Row {")
          let end = min(i + 3, present.count)
          for j in i..<end {
            let e = present[j]
            lines.append("  @Column {")
            lines.append("    \(e.emoji) \(e.title)")
            lines.append("  }")
          }
          lines.append("}")
          lines.append("")
          i = end
        }
      }
      // Use DocC Topics for proper navigation/section grouping
      lines.append("## Topics")
      lines.append("")
      for entry in ordered {
        guard let items = docsByType[entry.key], !items.isEmpty else { continue }
        // Render standard Markdown links; avoid @Links which interfered with doc: resolution
        lines.append("### \(entry.emoji) \(entry.title)")
        for id in items.sorted() { lines.append("- <doc:\(id)>") }
        lines.append("")
      }
      return lines.joined(separator: "\n")
    }

    private struct FrontMatter: Decodable { let expertiseTypes: [String]? }

    private func extractExpertiseTypes(from url: URL) throws -> [String]? {
      let content = try String(contentsOf: url, encoding: .utf8)
      let prefix = content.prefix(2000)  // keep for legacy comment parsing
      let s = String(prefix)
      // HTML comment JSON front matter
      if let start = s.range(of: "<!--"), let end = s.range(of: "-->") {
        let json = s[start.upperBound..<end.lowerBound]
        if let data = json.data(using: .utf8),
          let fm = try? JSONDecoder().decode(FrontMatter.self, from: data)
        {
          return fm.expertiseTypes
        }
        // Also support a lightweight CSV variant inside an HTML comment to avoid DocC interference:
        // Example: <!-- expertiseTypes: doc, design -->
        let lower = json.lowercased()
        if let keyRange = lower.range(of: "expertisetypes:") {
          let after = lower[keyRange.upperBound...]
          // Trim until end of comment
          let raw = after.trimmingCharacters(in: .whitespacesAndNewlines)
          let csv =
            raw
            .replacingOccurrences(of: "-->", with: "")
            .replacingOccurrences(of: "\n", with: " ")
          let parts =
            csv
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
          if !parts.isEmpty { return parts }
        }
      }
      // Fenced code block json
      if let start = s.range(of: "```json"),
        let end = s.range(of: "```", range: start.upperBound..<s.endIndex)
      {
        let json = s[start.upperBound..<end.lowerBound]
        if let data = json.data(using: .utf8),
          let fm = try? JSONDecoder().decode(FrontMatter.self, from: data)
        {
          return fm.expertiseTypes
        }
      }
      // Metadata-based typing (preferred; does not interfere with DocC)
      // Scan full content for @PageImage source and @PageColor.
      func typesFrom(iconBase: String?, color: String?) -> [String]? {
        var out: [String] = []
        if let icon = iconBase?.lowercased() {
          if icon.contains("icon-docc") { out.append("doc") }
          if icon.contains("icon-templates") || icon.contains("icon-motifs") {
            out.append("design")
          }
          if icon.contains("icon-passkit") { out.append("example") }
          if icon.contains("icon-repo") { out.append("infra") }
          if icon.contains("icon-tool") || icon.contains("icon-spec") { out.append("tool") }
          if icon.contains("icon-triads") { out.append("doc") }
          if icon.contains("icon-warning") || icon.contains("icon-note")
            || icon.contains("icon-error")
          {
            out.append("doc")
          }
        }
        if out.isEmpty, let c = color?.lowercased() {
          switch c {
          case "blue": out.append("doc")
          case "orange": out.append("tool")
          case "green": out.append("infra")
          case "purple": out.append("example")
          case "gray": out.append("design")
          default: break
          }
        }
        return out.isEmpty ? nil : Array(Set(out))
      }
      var iconBase: String? = nil
      var pageColor: String? = nil
      // Naive scans
      if let r = content.range(of: "@PageImage("),
        let sr = content[r.lowerBound...].range(of: "source:")
      {
        let after = content[sr.upperBound...]
        if let q1 = after.firstIndex(of: "\""),
          let q2 = after.index(q1, offsetBy: 1, limitedBy: after.endIndex).flatMap({
            after[$0...].firstIndex(of: "\"")
          })
        {
          let value = after[
            after.index(
              after.startIndex, offsetBy: after.distance(from: after.startIndex, to: q1) + 1)..<q2]
          iconBase = String(value)
        }
      }
      if let cr = content.range(of: "@PageColor("),
        let close = content[cr.upperBound...].firstIndex(of: ")")
      {
        pageColor = String(content[cr.upperBound..<close]).trimmingCharacters(
          in: .whitespacesAndNewlines)
      }
      if let types = typesFrom(iconBase: iconBase, color: pageColor) { return types }
      return nil
    }

    private func resolveContributorSystemDocId(from expertiseDocIds: [String]) -> String? {
      for docId in expertiseDocIds {
        let lowercased = docId.lowercased()
        if lowercased.contains("s-type")
          || lowercased.contains("s-types")
          || lowercased.contains("contribution-system")
          || lowercased.contains("contribution")
        {
          return docId
        }
      }
      return nil
    }

    private func renderMemoryRoot(
      slug: String,
      agentDoc: AgentDoc,
      avatarBase: String?,
      heroBannerBase: String,
      figletBanner: String?,
      reveries: ReveriesContent?,
      expertiseDocIds: [String],
      journalDocIds: [String]
    ) -> String {
      let purpose = agentDoc.purpose?.trimmingCharacters(in: .whitespacesAndNewlines)
      var lines: [String] = []
      lines.append("# ^\(slug): Memory")
      lines.append("")
      lines.append("@Metadata {")
      lines.append("  @TechnologyRoot")
      lines.append("  @TitleHeading(\"^\(slug): Memory\")")
      lines.append(
        "  @PageImage(purpose: card, source: \"\(heroBannerBase)\", alt: \"^\(slug) hero banner\")")
      lines.append("}")
      lines.append("")
      lines.append(contentsOf: renderFigletBlock(figletBanner))
      lines.append("@Image(source: \"\(heroBannerBase)\", alt: \"^\(slug) hero banner\")")
      lines.append("")
      if let avatarBase {
        lines.append("@Image(source: \"\(avatarBase)\", alt: \"^\(slug) avatar\")")
        lines.append("")
      } else {
        lines.append("_Avatar placeholder._")
        lines.append("")
      }
      lines.append("^\(slug) memory pairs expertise and journal entries.")
      lines.append("")
      if let purpose, !purpose.isEmpty {
        lines.append("## Mission")
        lines.append("")
        lines.append(purpose)
        lines.append("")
      }
      lines.append(contentsOf: renderCharacterSheet(from: agentDoc))
      if let reveries {
        lines.append(contentsOf: renderReveriesSection(reveries))
      }
      lines.append("## Topics")
      lines.append("")
      lines.append("### Expertise")
      for docId in expertiseDocIds {
        lines.append("- <doc:\(docId)>")
      }
      lines.append("")
      lines.append("### Journal")
      for docId in journalDocIds {
        lines.append("- <doc:\(docId)>")
      }
      lines.append("")
      return lines.joined(separator: "\n")
    }

    private func findRepoRoot(startingAt url: URL) -> URL? {
      var current = url
      let fileManager = FileManager.default
      while true {
        let agency = current.appendingPathComponent("AGENCY.md")
        let clia = current.appendingPathComponent(".clia")
        if fileManager.fileExists(atPath: agency.path) || fileManager.fileExists(atPath: clia.path)
        {
          return current
        }
        let parent = current.deletingLastPathComponent()
        if parent.path == current.path { return nil }
        current = parent
      }
    }
  }
}

private struct TriadFiles {
  let agentURL: URL
  let agendaURL: URL
  let agencyURL: URL
}

private struct TriadDocs {
  let agentMarkdown: String
  let agendaMarkdown: String
  let agencyMarkdown: String
}

private struct ResourceMapping {
  let originalFileName: String
  let newFileName: String
  let originalBaseName: String
  let newBaseName: String
}

extension String {
  fileprivate var deletingPathExtensionName: String {
    let url = URL(fileURLWithPath: self)
    return url.deletingPathExtension().lastPathComponent
  }
}
