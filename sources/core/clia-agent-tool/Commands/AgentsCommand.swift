import ArgumentParser
import CLIAAgentCore
import CLIAAgentCoreCLICommands
import CLIACore
import CLIACoreModels
import CommonShell
import Foundation
import WrkstrmFoundation
import WrkstrmMain

struct Agents: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "agents",
    abstract:
      "Agent workflows (commission, audit, validate-triad, context, preview, mirrors, generate-docc, render, transfer, journal, migrate-role)",
    subcommands: [
      Commission.self,
      Audit.self,
      ValidateTriad.self,
      TriadsLint.self,
      Context.self,
      PreviewAgent.self,
      PreviewAgenda.self,
      PreviewAgency.self,
      GenerateDocC.self,
      TypingPractice.self,
      SetContributionMix.self,
      SetFocusDomains.self,
      Transfer.self,
      MigrateRole.self,
      MigrateAgencyContributions.self,
    ]
  )
}

extension Agents {
  struct GenerateDocC: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "generate-docc",
      abstract: "Generate generated.docc + memory.docc bundles for an agent"
    )

    @Option(name: .customLong("slug"), help: "Agent slug")
    var slug: String

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    var path: String?

    @Option(
      name: .customLong("generated-bundle"),
      help: "Generated bundle directory name (default: generated.docc)")
    var generatedBundle: String = "generated.docc"

    @Option(
      name: .customLong("memory-bundle"),
      help: "Memory bundle directory name (default: memory.docc)")
    var memoryBundle: String = "memory.docc"

    @Flag(name: .customLong("write"), help: "Write bundles (default: dry run)")
    var write: Bool = false

    @Flag(name: .customLong("merged"), help: "Use merged triads across lineage when rendering")
    var merged: Bool = false

    @Flag(
      name: .customLong("include-launchpad-docc"), inversion: .prefixedNo,
      help: "Include .docc bundles found under spm/launchpad")
    var includeLaunchpadDocc: Bool = true

    func run() throws {
      var command = AgentDocCCommandGroup.Generate()
      command.slug = slug
      command.path = path
      command.generatedBundle = generatedBundle
      command.memoryBundle = memoryBundle
      command.write = write
      command.merged = merged
      command.includeLaunchpadDocc = includeLaunchpadDocc
      try command.run()
    }
  }

  // MARK: Typing practice generator
  struct TypingPractice: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "typing-practice",
      abstract: "Generate a typing-practice article from a source Markdown file with code blocks"
    )

    @Option(name: .customLong("source"), help: "Path to the source Markdown file")
    var source: String

    @Option(
      name: .customLong("bundle"), help: "DocC bundle directory (defaults to source's bundle)")
    var bundle: String?

    @Option(
      name: .customLong("name"), help: "Output article filename (default: typing-from-<slug>.md)")
    var name: String?

    @Option(name: .customLong("title"), help: "Page title (default: Typing practice: <slug>)")
    var title: String?

    @Flag(name: .customLong("write"), help: "Write the generated article (default: dry-run)")
    var write: Bool = false

    func run() throws {
      let srcURL = URL(fileURLWithPath: source)
      let content = try String(contentsOf: srcURL, encoding: .utf8)
      // Extract fenced code blocks (``` ... ```)
      var blocks: [String] = []
      var cur: [String]? = nil
      for line in content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
      {
        if line.starts(with: "```") {
          if let active = cur {
            blocks.append(active.joined(separator: "\n"))
            cur = nil
          } else {
            cur = []
          }
          continue
        }
        if cur != nil { cur!.append(line) }
      }
      guard !blocks.isEmpty else { throw ValidationError("No code blocks found in \(source)") }

      // Resolve bundle root and output path
      let bundleDir: URL = {
        if let b = bundle { return URL(fileURLWithPath: b) }
        // Walk up from source to find enclosing .docc directory
        var cur = srcURL.deletingLastPathComponent()
        let fm = FileManager.default
        while cur.path != "/" {
          if cur.lastPathComponent.hasSuffix(".docc") && fm.fileExists(atPath: cur.path) {
            return cur
          }
          cur.deleteLastPathComponent()
        }
        return srcURL.deletingLastPathComponent()
      }()
      let articles = bundleDir.appendingPathComponent("Articles", isDirectory: true)
      let slug = srcURL.deletingPathExtension().lastPathComponent
      let outName = name ?? "typing-from-\(slug).md"
      let outURL = articles.appendingPathComponent(outName)
      let pageTitle = title ?? "Typing practice: \(slug)"

      func escapeHTML(_ s: String) -> String {
        var r = s
        r = r.replacingOccurrences(of: "&", with: "&amp;")
        r = r.replacingOccurrences(of: "<", with: "&lt;")
        r = r.replacingOccurrences(of: ">", with: "&gt;")
        return r
      }

      var lines: [String] = []
      lines.append("@Metadata {")
      lines.append("  @PageColor(blue)")
      lines.append("  @TitleHeading(\"\(pageTitle)\")")
      lines.append(
        "  @PageImage(purpose: icon, source: \"cantina-system-design\", alt: \"Typing practice icon\")"
      )
      lines.append("}")
      lines.append("")
      lines.append(
        "@Image(source: \"code-swiftly.docc.css\", alt: \"Stylesheet\", purpose: decorative)")
      lines.append("")
      lines.append(
        "This page pulls code blocks directly from \(srcURL.lastPathComponent) and renders them as centered, Xcode‑like typing panels."
      )
      lines.append("")
      for (idx, block) in blocks.enumerated() {
        lines.append("## Exercise \(idx + 1)")
        lines.append("")
        lines.append("<div class=\"typing-container\">")
        lines.append("  <div class=\"typing-title\">Type the code below</div>")
        lines.append(
          "  <div class=\"typing-editor with-gutter\" contenteditable=\"true\" spellcheck=\"false\" aria-label=\"Typing editor\">"
        )
        for line in block.split(separator: "\n", omittingEmptySubsequences: false) {
          lines.append("<div>\(escapeHTML(String(line)))</div>")
        }
        lines.append("  </div>")
        lines.append("</div>")
        lines.append("")
      }
      let output = lines.joined(separator: "\n") + "\n"
      if write {
        try FileManager.default.createDirectory(at: articles, withIntermediateDirectories: true)
        try output.write(to: outURL, atomically: true, encoding: .utf8)
        print(outURL.path)
      } else {
        print("would write \(outURL.path)")
      }
    }
  }

  struct Commission: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "commission",
      abstract: "Commission a CLIA agent triad under .clia/agents/"
    )

    // MARK: Inputs
    @Argument(help: "Agent slug (kebab-case, lowercase)")
    var slug: String

    @Option(name: .customLong("title"), help: "Human-friendly agent title")
    var title: String?

    @Option(name: .customLong("mission"), help: "Override the default mission paragraph")
    var mission: String?

    enum AgentRole: String, ExpressibleByArgument, CaseIterable {
      case maintainer
      case documentor
      case productOwner = "product-owner"
      case productManager = "product-manager"
      case swiftArchitect = "swift-architect"
      case testEngineer = "test-engineer"
      case releaseCaptain = "release-captain"
      case opsEngineer = "ops-engineer"

      var displayName: String {
        switch self {
        case .maintainer: return "Maintainer"
        case .documentor: return "Documentor"
        case .productOwner: return "Product Owner"
        case .productManager: return "Product Manager"
        case .swiftArchitect: return "Swift Architect"
        case .testEngineer: return "Test Engineer"
        case .releaseCaptain: return "Release Captain"
        case .opsEngineer: return "Ops Engineer"
        }
      }

      var description: String {
        switch self {
        case .maintainer:
          return "Swift iOS maintainer: guards code health, dependencies, and release readiness."
        case .documentor:
          return "Swift iOS documentor: translates features into DocC, guides, and release notes."
        case .productOwner:
          return
            "Product owner: aligns roadmap, outcomes, and sprint delivery (renamed from product-manager)."
        case .productManager:
          return "Product manager: aligns roadmap, outcomes, and sprint delivery."
        case .swiftArchitect:
          return "Swift architect: stewards modular design, performance, and layering."
        case .testEngineer:
          return "Test engineer: enforces automation, CI signal, and release gates."
        case .releaseCaptain:
          return
            "Release captain: orchestrates TestFlight/App Store rollout and post-launch analytics."
        case .opsEngineer:
          return "Ops engineer: maintains pipelines, monitoring, and infrastructure reliability."
        }
      }
    }

    @Option(
      name: .customLong("role"),
      help:
        "Preconfigure templates for a specific role: \(AgentRole.allCases.map { $0.rawValue }.joined(separator: ", "))"
    )
    var role: AgentRole?

    @Option(name: .customLong("root"), help: "Path to repo root (defaults to current directory)")
    var root: String?

    @Flag(name: .customLong("force"), help: "Overwrite existing agent directory if present")
    var force: Bool = false

    @Flag(name: .customLong("with-markdown"), help: "Also emit Markdown mirrors for human reading")
    var withMarkdown: Bool = false

    // MARK: Behavior
    mutating func run() async throws {
      let fm = FileManager.default
      let workingRoot = URL(fileURLWithPath: root ?? fm.currentDirectoryPath)
      let cliaRoot = workingRoot.appendingPathComponent(".clia")
      guard fm.fileExists(atPath: cliaRoot.path) else {
        throw ValidationError(
          "CLIA stack not found at \(cliaRoot.path). Run from repo root or pass --root.")
      }

      let templatesRoot = cliaRoot.appendingPathComponent("templates/agents")
      if withMarkdown {
        guard fm.fileExists(atPath: templatesRoot.path) else {
          throw ValidationError("Agent templates missing at \(templatesRoot.path)")
        }
      }

      let normalizedSlug = slugify(slug)
      let agentTitle = title ?? titleFromSlug(normalizedSlug)
      let commissionDate = isoDate()

      var values = placeholderValues(slug: normalizedSlug, title: agentTitle, mission: mission)
      if let role {
        values.merge(rolePlaceholderOverrides(for: role, title: agentTitle)) { _, new in new }
      }
      values["COMMISSION_DATE"] = commissionDate

      let agentDir = cliaRoot.appendingPathComponent("agents/\(normalizedSlug)")
      if fm.fileExists(atPath: agentDir.path) {
        guard force else {
          throw ValidationError(
            "Agent already exists at \(agentDir.path). Use --force to overwrite.")
        }
        try fm.removeItem(at: agentDir)
      }
      try fm.createDirectory(at: agentDir, withIntermediateDirectories: true)

      if withMarkdown {
        let generatedDir = agentDir.appendingPathComponent(".generated")
        try fm.createDirectory(at: generatedDir, withIntermediateDirectories: true)
        try renderTemplate(
          named: "agent.md.stencil",
          to: generatedDir.appendingPathComponent("\(normalizedSlug).agent.triad.md"),
          role: role,
          values: values,
          templatesRoot: templatesRoot
        )
        try renderTemplate(
          named: "agenda.md.stencil",
          to: generatedDir.appendingPathComponent("\(normalizedSlug).agenda.triad.md"),
          role: role,
          values: values,
          templatesRoot: templatesRoot
        )
        try renderTemplate(
          named: "agency.md.stencil",
          to: generatedDir.appendingPathComponent("\(normalizedSlug).agency.triad.md"),
          role: role,
          values: values,
          templatesRoot: templatesRoot
        )
      }

      try registerAgentInRoster(
        slug: normalizedSlug,
        title: agentTitle,
        mission: values["AGENT_MISSION"] ?? "",
        root: workingRoot
      )

      try emitJSONTriad(
        at: agentDir,
        slug: normalizedSlug,
        title: agentTitle,
        workingRoot: workingRoot,
        values: values,
        withMarkdown: withMarkdown
      )

      print("Bounty accepted: \(agentTitle) → \(agentDir.path)")
    }

    // MARK: Rendering helpers
    private func renderTemplate(
      named template: String,
      to destination: URL,
      role: AgentRole?,
      values: [String: String],
      templatesRoot: URL
    ) throws {
      let fm = FileManager.default
      var templateURL = templatesRoot.appendingPathComponent(template)
      if let role {
        let roleURL =
          templatesRoot
          .appendingPathComponent("roles")
          .appendingPathComponent(role.rawValue)
          .appendingPathComponent(template)
        if fm.fileExists(atPath: roleURL.path) {
          templateURL = roleURL
        }
      }
      guard fm.fileExists(atPath: templateURL.path) else {
        throw ValidationError("Template missing: \(templateURL.path)")
      }
      var content = try String(contentsOf: templateURL, encoding: .utf8)
      for (key, value) in values {
        content = content.replacingOccurrences(of: "{{\(key)}}", with: value)
      }
      try content.write(to: destination, atomically: true, encoding: .utf8)
    }

    private func registerAgentInRoster(slug: String, title: String, mission: String, root: URL)
      throws
    {
      let rosterURL = root.appendingPathComponent("AGENTS.md")
      guard FileManager.default.fileExists(atPath: rosterURL.path) else { return }
      var contents = try String(contentsOf: rosterURL, encoding: .utf8)
      let summary = singleLine(mission)
      let row = "| \(title) | \(summary) | `.clia/agents/\(slug)/` |"
      if contents.contains(row) { return }

      var lines = contents.components(separatedBy: "\n")
      lines.removeAll { $0.contains("_(commissioned via CLI)_") }
      if let headerIndex = lines.firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces) == "| ----- | ------- | -------- |"
      }) {
        lines.insert(row, at: headerIndex + 1)
      } else {
        lines.append(row)
      }
      contents =
        lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
      try contents.write(to: rosterURL, atomically: true, encoding: .utf8)
    }

    // MARK: Schema fillers (0.2.0)
    private func placeholderValues(slug: String, title: String, mission: String?) -> [String:
      String]
    {
      let defaultMission =
        "Describe this agent's purpose. Tie it back to the DocC mission article for the app or library."
      let missionText = mission?.trimmingCharacters(in: .whitespacesAndNewlines)
      return [
        "AGENT_SLUG": slug,
        "AGENT_TITLE": title,
        "AGENT_MISSION": (missionText?.isEmpty == false ? missionText! : defaultMission),
        "DOCC_MISSION_REF": "Sources/<Module>.docc/TheMission.md",
        "CAPABILITY_ONE": "List core strengths or tools.",
        "CAPABILITY_TWO": "Mention any guardrails or scope boundaries.",
        "RITUAL_STEP_ONE": "Outline how the agent begins a session.",
        "RITUAL_STEP_TWO": "Capture checkpoints (for example, sync with CLIA timers).",
        "RITUAL_STEP_THREE": "Document how the agent closes the loop.",
        "ESCALATION_PATH": "Specify when humans or other agents must be notified.",
        "DAILY_FOCUS": "Summarize the daily objective.",
        "WEEKLY_FOCUS": "Describe a longer-horizon review.",
        "ADHOC_FOCUS": "Capture triggers for special sessions.",
        "BACKLOG_ITEM_ONE": "Seed the first initiative.",
        "BACKLOG_ITEM_TWO": "Add another action item.",
        "DEPENDENCY_NOTE": "Reference other agents, services, or data feeds.",
        "HIGHLIGHT_NOTE": "Record achievements, deliverables, or escalations.",
        "NEXT_STEP": "Outline what the agent should tackle next.",
      ]
    }

    private func rolePlaceholderOverrides(for role: AgentRole, title: String) -> [String: String] {
      switch role {
      case .maintainer:
        return [
          "AGENT_MISSION":
            "Maintain Swift application health so each release stays shippable and aligned with the DocC mission.",
          "CAPABILITY_ONE": "Run CI, unit, UI, and smoke tests to keep baseline quality high.",
          "CAPABILITY_TWO":
            "Plan dependency upgrades and monitor crash-free metrics and performance budgets.",
          "RITUAL_STEP_ONE":
            "Review CI dashboards and run `swift test --parallel` on the default branch.",
          "RITUAL_STEP_TWO":
            "Audit dependency advisories and log upgrade actions in the maintenance backlog.",
          "RITUAL_STEP_THREE":
            "Publish a maintenance summary to AGENCY with findings, blockers, and next steps.",
          "ESCALATION_PATH":
            "Notify release captain and security when blockers impact stability or compliance.",
          "DAILY_FOCUS": "Sweep CI results, crash analytics, and open maintenance tickets.",
          "WEEKLY_FOCUS": "Bundle maintenance PRs (deps, lint, flaky tests) for review.",
          "ADHOC_FOCUS": "Respond to high-severity regressions within the on-call window.",
          "BACKLOG_ITEM_ONE": "Automate dependency vulnerability scanning in CI.",
          "BACKLOG_ITEM_TWO": "Document maintenance SLAs in DocC / README.",
          "DEPENDENCY_NOTE":
            "CI pipelines, test suites, analytics dashboards, dependency manifests.",
          "HIGHLIGHT_NOTE": "Record crash-free %, upgrades merged, and technical debt burndown.",
          "NEXT_STEP": "Plan the next maintenance window and update the schedule in AGENCY.",
        ]
      case .documentor:
        return [
          "AGENT_MISSION":
            "Capture Swift product knowledge in DocC, guides, and release notes so teams share a single source of truth.",
          "CAPABILITY_ONE":
            "Author DocC tutorials and how-to docs with annotated screenshots and sample code.",
          "CAPABILITY_TWO":
            "Draft human-friendly release notes and keep README / changelog in sync.",
          "RITUAL_STEP_ONE":
            "Review merged PRs and collect assets (screenshots, API diffs, metrics).",
          "RITUAL_STEP_TWO": "Update DocC bundles, README tables, and Knowledge Base entries.",
          "RITUAL_STEP_THREE": "Publish a documentation digest to AGENCY and tag reviewers.",
          "ESCALATION_PATH": "Alert product/compliance if gaps block release or onboarding.",
          "DAILY_FOCUS":
            "Record incremental UI/UX changes with accessibility and localization notes.",
          "WEEKLY_FOCUS": "Ship a doc changelog + DocC preview for stakeholders.",
          "ADHOC_FOCUS": "Respond to audit or customer documentation requests within SLA.",
          "BACKLOG_ITEM_ONE": "Convert latest feature walkthrough into DocC tutorial.",
          "BACKLOG_ITEM_TWO": "Create reusable release note templates for upcoming launches.",
          "DEPENDENCY_NOTE": "DocC bundles, Style guide, Knowledge base, Release notes repo.",
          "HIGHLIGHT_NOTE": "Link to DocC previews, changelog entries, and reviewer signoffs.",
          "NEXT_STEP": "Plan the next documentation sprint and schedule reviews.",
        ]
      case .productOwner, .productManager:
        return [
          "AGENT_MISSION":
            "Align roadmap, OKRs, and stakeholder outcomes to deliver the DocC mission.",
          "CAPABILITY_ONE": "Define north stars, themes, and measurable outcomes.",
          "CAPABILITY_TWO":
            "Prioritize initiatives, milestones, and secure cross-team commitments.",
          "RITUAL_STEP_ONE": "Gather insights from customers, telemetry, and delivery risks.",
          "RITUAL_STEP_TWO": "Update Agenda and AGENCY with plans and progress.",
          "RITUAL_STEP_THREE": "Share a clear weekly plan and unblock teams.",
          "ESCALATION_PATH": "Escalate cross-team blockers and dependency risks promptly.",
          "DAILY_FOCUS": "Clarify priorities and reduce uncertainty for the team.",
          "WEEKLY_FOCUS": "Evaluate outcomes against the north star and adjust.",
          "ADHOC_FOCUS": "Coordinate incident response and customer comms when needed.",
          "BACKLOG_ITEM_ONE": "Draft north star metrics and first themes.",
          "BACKLOG_ITEM_TWO": "Schedule stakeholder reviews for top initiatives.",
          "DEPENDENCY_NOTE": "Customer research, analytics, engineering pipeline health.",
          "HIGHLIGHT_NOTE": "Capture value delivered and learning milestones.",
          "NEXT_STEP": "Plan next iteration with clear acceptance criteria.",
        ]
      case .swiftArchitect:
        return [
          "AGENT_MISSION":
            "Steward modular architecture and performance while enabling fast iteration.",
          "CAPABILITY_ONE": "Define layering, reuse boundaries, and typed adapters.",
          "CAPABILITY_TWO": "Guide migrations and enforce performance budgets.",
          "RITUAL_STEP_ONE": "Review hotspots and perf regressions.",
          "RITUAL_STEP_TWO": "Shepherd shared libraries; reduce drift.",
          "RITUAL_STEP_THREE": "Publish design notes in DocC.",
          "ESCALATION_PATH": "Flag risky shortcuts that jeopardize maintainability.",
          "DAILY_FOCUS": "Unblock teams with crisp, typed APIs.",
          "WEEKLY_FOCUS": "Align architecture roadmap with delivery.",
          "ADHOC_FOCUS": "Support incident response with root-cause analysis.",
          "BACKLOG_ITEM_ONE": "Extract shared adapters into Common libraries.",
          "BACKLOG_ITEM_TWO": "Add tests for critical adapters.",
          "DEPENDENCY_NOTE": "WrkstrmMain/Foundations, CommonShell/CLI.",
          "HIGHLIGHT_NOTE": "Call out performance wins and simplifications.",
          "NEXT_STEP": "Propose next de-risking refactor.",
        ]
      case .testEngineer:
        return [
          "AGENT_MISSION":
            "Enforce automation, CI signal quality, and release gates across surfaces.",
          "CAPABILITY_ONE": "Design testing strategy, write Swift Testing suites.",
          "CAPABILITY_TWO": "Harden CI with fast, parallel runs and minimal flakes.",
          "RITUAL_STEP_ONE": "Sweep dashboards and triage failing tests.",
          "RITUAL_STEP_TWO": "Add missing coverage; codify repros.",
          "RITUAL_STEP_THREE": "Publish test health summary to AGENCY.",
          "ESCALATION_PATH": "Block releases when signal falls below thresholds.",
          "DAILY_FOCUS": "Keep signal trustworthy and actionable.",
          "WEEKLY_FOCUS": "Eliminate flakes and slow hotspots.",
          "ADHOC_FOCUS": "Respond to regressions with targeted fixes.",
          "BACKLOG_ITEM_ONE": "Migrate legacy XCTest to Swift Testing.",
          "BACKLOG_ITEM_TWO": "Add CI artifacts for faster diagnosis.",
          "DEPENDENCY_NOTE": "CI runners, test data, analytics.",
          "HIGHLIGHT_NOTE": "Show stability trends and time-to-fix.",
          "NEXT_STEP": "Enforce quality gates for high-risk areas.",
        ]
      case .releaseCaptain:
        return [
          "AGENT_MISSION": "Coordinate TestFlight/App Store rollout and post-release learning.",
          "CAPABILITY_ONE": "Run staged rollouts with metrics and guardrails.",
          "CAPABILITY_TWO": "Publish release notes and track follow-ups.",
          "RITUAL_STEP_ONE": "Prep builds, notes, and phased rollout plan.",
          "RITUAL_STEP_TWO": "Monitor metrics; pause/continue with data.",
          "RITUAL_STEP_THREE": "Write recap; capture learnings and actions.",
          "ESCALATION_PATH": "Coordinate incident comms with PO/Eng leads.",
          "DAILY_FOCUS": "Deliver value safely to users.",
          "WEEKLY_FOCUS": "Plan next release train.",
          "ADHOC_FOCUS": "Respond to incidents and feedback.",
          "BACKLOG_ITEM_ONE": "Automate release checklist integration with distribution APIs.",
          "BACKLOG_ITEM_TWO": "Create release recap template with KPIs and follow-up tasks.",
          "DEPENDENCY_NOTE": "Distribution portals, analytics, compliance documentation.",
          "HIGHLIGHT_NOTE": "Summarize rollout status, metrics, incidents, and next actions.",
          "NEXT_STEP": "Plan next release train and align stakeholders on scope.",
        ]
      case .opsEngineer:
        return [
          "AGENT_MISSION":
            "Maintain build pipelines, observability, and infrastructure needed to deliver the DocC mission reliably.",
          "CAPABILITY_ONE": "Own CI/CD stability, dependency scanning, and artifact retention.",
          "CAPABILITY_TWO":
            "Monitor runtime telemetry (crash, performance, backend health) and respond to incidents.",
          "RITUAL_STEP_ONE":
            "Check overnight pipelines, queue rebuilds, and capture failures in AGENCY.",
          "RITUAL_STEP_TWO": "Audit telemetry dashboards, ensure alerts reach on-call responders.",
          "RITUAL_STEP_THREE": "Document infra changes, costs, and follow-up tasks.",
          "ESCALATION_PATH":
            "Notify maintainers and release captain for sustained infra or security issues.",
          "DAILY_FOCUS": "Keep pipelines green and secrets/caches healthy.",
          "WEEKLY_FOCUS": "Run DR drills, dependency audits, and capacity planning.",
          "ADHOC_FOCUS": "Respond to incidents within on-call SLOs.",
          "BACKLOG_ITEM_ONE": "Introduce cache warming for SwiftPM dependencies in CI.",
          "BACKLOG_ITEM_TWO": "Automate pipeline telemetry export for dashboards.",
          "DEPENDENCY_NOTE":
            "CI runners, telemetry stack, secrets management, infrastructure-as-code.",
          "HIGHLIGHT_NOTE": "Report incidents handled, MTTR, and reliability improvements.",
          "NEXT_STEP": "Plan next infrastructure improvement sprint and document risks.",
        ]
      }
    }

    // MARK: JSON emission (schema 0.2.0)
    private func emitJSONTriad(
      at agentDir: URL,
      slug: String,
      title: String,
      workingRoot: URL,
      values: [String: String],
      withMarkdown: Bool
    ) throws {
      let fm = FileManager.default
      let dirTag = workingRoot.lastPathComponent
      let prefix = "\(slug)@\(dirTag)"

      let now = isoDate()

      let agentMD = agentDir.appendingPathComponent("\(slug).agent.triad.md")
      let agendaMD = agentDir.appendingPathComponent("\(slug).agenda.triad.md")
      let agencyMD = agentDir.appendingPathComponent("\(slug).agency.triad.md")

      func rel(_ url: URL) -> String? {
        guard fm.fileExists(atPath: url.path) else { return nil }
        let rootPath = workingRoot.path
        let p = url.path
        if p.hasPrefix(rootPath) {
          let rel = String(p.dropFirst(rootPath.count)).trimmingCharacters(
            in: CharacterSet(charactersIn: "/"))
          return rel.isEmpty ? nil : rel
        }
        return url.lastPathComponent
      }

      var agent = AgentDoc(
        slug: slug,
        title: title,
        updated: now,
        status: "draft",
        role: nil
      )
      if withMarkdown, let xsrc = rel(agentMD) { agent.sourcePath = xsrc }
      agent.purpose = values["AGENT_MISSION"].flatMap { $0.isEmpty ? nil : $0 }
      var resp: [String] = []
      if let c1 = values["CAPABILITY_ONE"], !c1.isEmpty { resp.append(c1) }
      if let c2 = values["CAPABILITY_TWO"], !c2.isEmpty { resp.append(c2) }
      agent.responsibilities = resp
      if let esc = values["ESCALATION_PATH"], !esc.isEmpty { agent.guardrails = [esc] }

      var agenda = AgendaDoc(
        slug: slug,
        title: title,
        updated: now,
        status: "draft",
        agent: .init(role: slug)
      )
      if withMarkdown, let xsrc = rel(agendaMD) { agenda.sourcePath = xsrc }
      var agendaBlocks: [NoteBlock] = []
      func addPara(_ key: String, _ label: String) {
        if let t = values[key], !t.isEmpty {
          agendaBlocks.append(NoteBlock(kind: "paragraph", text: ["\(label): \(t)"]))
        }
      }
      addPara("DAILY_FOCUS", "Daily")
      addPara("WEEKLY_FOCUS", "Weekly")
      addPara("ADHOC_FOCUS", "Ad-hoc")
      let backlog = [values["BACKLOG_ITEM_ONE"], values["BACKLOG_ITEM_TWO"]].compactMap { $0 }
        .filter { !$0.isEmpty }
      if !backlog.isEmpty { agendaBlocks.append(NoteBlock(kind: "list", text: backlog)) }
      agenda.notes = [Note(timestamp: nil, author: nil, blocks: agendaBlocks)]

      var agency = AgencyDoc(
        slug: slug,
        title: title,
        updated: now,
        status: "draft"
      )
      if withMarkdown, let xsrc = rel(agencyMD) { agency.sourcePath = xsrc }

      try JSON.FileWriter.write(
        agent,
        to: agentDir.appendingPathComponent("\(prefix).agent.json"),
        encoder: JSON.Formatting.humanEncoder
      )
      try JSON.FileWriter.write(
        agenda,
        to: agentDir.appendingPathComponent("\(prefix).agenda.json"),
        encoder: JSON.Formatting.humanEncoder
      )
      try JSON.FileWriter.write(
        agency,
        to: agentDir.appendingPathComponent("\(prefix).agency.json"),
        encoder: JSON.Formatting.humanEncoder
      )
    }

    // MARK: Utilities
    private func slugify(_ s: String) -> String {
      var result = ""
      var previousWasSeparator = false
      var previousWasAlphanumeric = false
      var previousWasLowerOrDigit = false
      for scalar in s.unicodeScalars {
        let ch = Character(scalar)
        if ch.isLetter || ch.isNumber {
          let isUpper = ch.isUppercase
          if isUpper && previousWasAlphanumeric && previousWasLowerOrDigit && !previousWasSeparator
          {
            result.append("-")
          }
          result.append(ch.lowercased())
          previousWasSeparator = false
          previousWasAlphanumeric = true
          previousWasLowerOrDigit = !isUpper
        } else {
          if !previousWasSeparator && !result.isEmpty { result.append("-") }
          previousWasSeparator = true
          previousWasAlphanumeric = false
          previousWasLowerOrDigit = false
        }
      }
      var collapsed = ""
      var lastWasHyphen = false
      for ch in result {
        if ch == "-" {
          if lastWasHyphen { continue }
          lastWasHyphen = true
          collapsed.append(ch)
        } else {
          lastWasHyphen = false
          collapsed.append(ch)
        }
      }
      return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func titleFromSlug(_ slug: String) -> String {
      slug.split(separator: "-").map { word in
        guard let first = word.first else { return "" }
        let head = String(first).uppercased()
        let tail = String(word.dropFirst())
        return head + tail
      }.joined(separator: " ")
    }

    private func singleLine(_ text: String) -> String {
      text.split(whereSeparator: { $0.isNewline }).joined(separator: " ")
    }

    private func isoDate() -> String {
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return f.string(from: Date())
    }
  }
}

// MARK: - Set contribution mix

extension Agents {
  struct SetContributionMix: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-contribution-mix",
      abstract: "Set an agent's contributionMix (primary/secondary role weights)"
    )

    @Option(name: .customLong("slug"), help: "Agent slug (kebab-case)")
    var slug: String

    @Option(
      name: .customLong("primary"),
      help: "CSV type[=weight] items (e.g., code=5,design=2,doc=1). Weight omitted defaults to 1")
    var primaryCSV: String

    @Option(
      name: .customLong("secondary"),
      help: "CSV type[=weight] items (optional). Weight omitted defaults to 1")
    var secondaryCSV: String?

    @Option(
      name: .customLong("contribution-focus"),
      parsing: .upToNextOption,
      help: "Contribution types to focus/allow (kebab-case)"
    )
    var contributionFocus: [String] = []

    @Option(
      name: .customLong("s-type-contribution-map"),
      help: "Path to S-Types contribution map JSON (spec.types keys are allowed types)"
    )
    var sTypeContributionMap: String?

    @Flag(
      name: .customLong("merge"), help: "Merge with existing mix (last-wins) instead of replace")
    var merge: Bool = false

    @Flag(name: .customLong("dry-run"), help: "Print planned change; do not write")
    var dryRun: Bool = false

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    var path: String?

    func run() throws {
      let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
      let fm = FileManager.default
      guard
        let fileURL = try fm.contentsOfDirectory(
          at: target.agentDir, includingPropertiesForKeys: nil
        )
        .first(where: { $0.lastPathComponent.contains(".agent.") && $0.pathExtension == "json" })
      else { throw ValidationError("*.agent.json not found for \(slug)") }

      let decoder = JSONDecoder()
      var doc = try decoder.decode(AgentDoc.self, from: Data(contentsOf: fileURL))

      func parse(_ csv: String) throws -> [Contribution] {
        let parts = csv.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !parts.isEmpty else { throw ValidationError("empty list: \(csv)") }
        var out: [Contribution] = []
        for raw in parts {
          let p = raw
          if let eq = p.firstIndex(of: "=") {
            let type = String(p[..<eq]).trimmingCharacters(in: .whitespaces)
            let valS = String(p[p.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            let w: Double
            if valS.isEmpty {
              w = 1.0
            } else if let dv = Double(valS) {
              w = dv
            } else {
              throw ValidationError("invalid weight for \(type): \(valS)")
            }
            out.append(.init(type: type, weight: w))
          } else {
            let type = String(p).trimmingCharacters(in: .whitespaces)
            guard !type.isEmpty else { throw ValidationError("empty type token in list: \(csv)") }
            out.append(.init(type: type, weight: 1.0))
          }
        }
        return out
      }

      let primary = try parse(primaryCSV)
      let secondary = try secondaryCSV.map { try parse($0) }
      var newMix = ContributionMix(primary: primary, secondary: secondary)

      // Build contribution focus set from --contribution-focus and/or --s-type-contribution-map
      var allowed: Set<String> = Set(contributionFocus)
      if let sTypeContributionMap {
        let specURL = URL(fileURLWithPath: sTypeContributionMap)
        let data = try Data(contentsOf: specURL)
        if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let types = obj["types"] as? [String: Any]
        {
          allowed.formUnion(Set(types.keys))
        }
      }
      if !allowed.isEmpty {
        let unknown = newMix.unknownRoles(allowed: allowed)
        if !unknown.isEmpty {
          throw ValidationError("unknown contribution types: \(unknown.joined(separator: ", "))")
        }
      }
      let invalid = newMix.invalidWeights()
      if !invalid.isEmpty {
        throw ValidationError("non-positive weights: \(invalid.joined(separator: ", "))")
      }

      if merge, let existing = doc.contributionMix {
        func mergeLists(_ a: [Contribution], _ b: [Contribution]) -> [Contribution] {
          var map: [String: Double] = [:]
          for c in a { map[c.type] = c.weight }
          for c in b { map[c.type] = c.weight }
          return map.map { Contribution(type: $0.key, weight: $0.value) }
        }
        let mergedPrimary = mergeLists(existing.primary, primary)
        let mergedSecondary = mergeLists(existing.secondary ?? [], secondary ?? [])
        newMix = ContributionMix(
          primary: mergedPrimary, secondary: mergedSecondary.isEmpty ? nil : mergedSecondary)
      }

      doc.contributionMix = newMix

      if dryRun {
        let enc = JSON.Formatting.humanEncoder
        let data = try enc.encode(doc)
        if let s = String(data: data, encoding: .utf8) { print(s) }
        return
      }

      try JSON.FileWriter.write(doc, to: fileURL, encoder: JSON.Formatting.humanEncoder)
      print(
        "Updated contributionMix for \(slug): primary=\(newMix.primary.count) items, secondary=\(newMix.secondary?.count ?? 0) items"
      )
    }
  }
}

// MARK: - Set focus domains

extension Agents {
  struct SetFocusDomains: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "set-focus-domains",
      abstract: "Set an agent's focusDomains (label, identifier, optional weight)"
    )

    @Option(name: .customLong("slug"), help: "Agent slug (kebab-case)")
    var slug: String

    @Option(
      name: .customLong("domain"), parsing: .upToNextOption,
      help:
        "Focus domain entry as 'Label=identifier[:weight]'. Weight omitted defaults to 1. Repeat to add multiple."
    )
    var domainSpecs: [String] = []

    @Flag(name: .customLong("merge"), help: "Merge with existing list (last-wins by slug)")
    var merge: Bool = false

    @Flag(name: .customLong("dry-run"), help: "Print planned change; do not write")
    var dryRun: Bool = false

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    var path: String?

    func run() throws {
      guard !domainSpecs.isEmpty else { throw ValidationError("at least one --domain is required") }
      let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
      let fm = FileManager.default
      guard
        let fileURL = try fm.contentsOfDirectory(
          at: target.agentDir, includingPropertiesForKeys: nil
        )
        .first(where: { $0.lastPathComponent.contains(".agent.") && $0.pathExtension == "json" })
      else { throw ValidationError("*.agent.json not found for \(slug)") }

      let decoder = JSONDecoder()
      var doc = try decoder.decode(AgentDoc.self, from: Data(contentsOf: fileURL))

      func parse(_ spec: String) throws -> CLIACoreModels.FocusDomain {
        // Format: Label=identifier[:weight]
        guard let eq = spec.firstIndex(of: "=") else {
          throw ValidationError("missing '=' in domain spec: \(spec)")
        }
        let label = String(spec[..<eq]).trimmingCharacters(in: .whitespaces)
        let rest = String(spec[spec.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
        let parts = rest.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count >= 1 else {
          throw ValidationError("missing identifier in domain spec: \(spec)")
        }
        let identifier = parts[0].trimmingCharacters(in: .whitespaces)
        var weight: Double? = 1.0
        if parts.count == 2 {
          guard let w = Double(parts[1]) else {
            throw ValidationError("invalid weight in domain spec: \(spec)")
          }
          weight = w
        }
        let valid = identifier.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil
        if !valid {
          throw ValidationError("invalid identifier (allowed: A-Za-z0-9._-): \(identifier)")
        }
        return .init(label: label, identifier: identifier, weight: weight)
      }

      let newItems = try domainSpecs.map(parse)

      if merge, let existing = doc.focusDomains {
        var map: [String: CLIACoreModels.FocusDomain] = [:]
        for e in existing { map[e.identifier] = e }
        for n in newItems { map[n.identifier] = n }
        doc.focusDomains = Array(map.values)
      } else {
        doc.focusDomains = newItems
      }

      if dryRun {
        let enc = JSON.Formatting.humanEncoder
        let data = try enc.encode(doc)
        if let s = String(data: data, encoding: .utf8) { print(s) }
        return
      }

      try JSON.FileWriter.write(doc, to: fileURL, encoder: JSON.Formatting.humanEncoder)
      print("Updated focusDomains for \(slug): \(doc.focusDomains?.count ?? 0) items")
    }
  }
}

// MARK: - Audit (local or docs)

extension Agents {
  struct Audit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "audit",
      abstract: "Audit a CLIA agent triad (engine: local|docs)"
    )

    enum Engine: String, ExpressibleByArgument { case local, docs }

    @Option(name: .customLong("engine"), help: "local (in-process) or docs (in-process)")
    var engine: Engine = .local

    @Option(name: .customLong("slug"), help: "Agent slug (kebab-case)")
    var slug: String

    @Option(name: .customLong("path"), help: "Working directory (defaults to CWD)")
    var path: String?

    @Flag(name: .customLong("with-sources"), help: "Include provenance in merged outputs (local)")
    var withSources: Bool = false

    @Flag(
      name: .customLong("show-duplicates"),
      help: "Include per-source arrays that preserve duplicates (local)")
    var showDuplicates: Bool = false

    @Flag(
      name: .customLong("root-chain"),
      help: "Include lineage context chain (prefix+path) in output (local)")
    var rootChain: Bool = false

    @Flag(name: .customLong("preview-agent"), help: "Print merged agent view (local)")
    var previewAgent: Bool = false
    @Flag(name: .customLong("preview-agenda"), help: "Print merged agenda view (local)")
    var previewAgenda: Bool = false
    @Flag(name: .customLong("preview-agency"), help: "Print merged agency view (local)")
    var previewAgency: Bool = false

    // docs engine now runs in-process; kept for compatibility (no-op)
    @Flag(name: .customLong("rebuild-release"), help: "(no-op) docs engine runs in-process")
    var rebuildRelease: Bool = false

    @Flag(name: .customLong("strict"), help: "Exit non-zero on validation errors")
    var strict: Bool = false

    mutating func run() async throws {
      switch engine {
      case .local:
        try runLocal()
      case .docs:
        try runLocal()  // parity: docs engine uses same in-process implementation
      }
    }

    private func runLocal() throws {
      let fm = FileManager.default
      let work = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      let agentsDir = work.appendingPathComponent(".clia/agents/\(slug)")
      guard fm.fileExists(atPath: agentsDir.path) else {
        throw ValidationError("Agent dir not found: \(agentsDir.path)")
      }

      let files = try fm.contentsOfDirectory(at: agentsDir, includingPropertiesForKeys: nil)
      guard
        let agentURL = files.first(where: {
          $0.lastPathComponent.hasSuffix(".agent.json")
            && !$0.lastPathComponent.contains(".agency.")
        })
      else {
        throw ValidationError("Missing *.agent.json in \(agentsDir.path)")
      }
      guard let agendaURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agenda.json") })
      else {
        throw ValidationError("Missing *.agenda.json in \(agentsDir.path)")
      }
      guard let agencyURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agency.json") })
      else {
        throw ValidationError("Missing *.agency.json in \(agentsDir.path)")
      }

      let dec = JSONDecoder()
      let agent = try dec.decode(AgentDoc.self, from: Data(contentsOf: agentURL))
      let agenda = try dec.decode(AgendaDoc.self, from: Data(contentsOf: agendaURL))
      let agency = try dec.decode(AgencyDoc.self, from: Data(contentsOf: agencyURL))

      var errors: [String] = []
      var warns: [String] = []
      // Slug alignment
      if agent.slug != slug { errors.append("agent.slug != \(slug)") }
      if agenda.slug != slug { errors.append("agenda.slug != \(slug)") }
      if agency.slug != slug { errors.append("agency.slug != \(slug)") }
      // Agent slug alignment (use document slug)
      if agent.slug != slug { errors.append("agent.slug != slug") }
      if agenda.agent.role != slug { errors.append("agenda.agent.role != slug") }
      // Title non-empty
      if agent.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        warns.append("agent.title empty")
      }
      if agenda.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        warns.append("agenda.title empty")
      }
      if agency.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        warns.append("agency.title empty")
      }
      // Updated ISO8601
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if f.date(from: agent.updated) == nil {
        warns.append("agent.updated not ISO8601 with fractional seconds")
      }
      if f.date(from: agenda.updated) == nil {
        warns.append("agenda.updated not ISO8601 with fractional seconds")
      }
      if f.date(from: agency.updated) == nil {
        warns.append("agency.updated not ISO8601 with fractional seconds")
      }
      // sourcePath relative
      func checkSourcePath(_ path: String?, _ label: String) {
        guard let x = path, !x.isEmpty else { return }
        if x.hasPrefix("/") || (x.count > 1 && x[x.index(x.startIndex, offsetBy: 1)] == ":") {
          warns.append("\(label).sourcePath is absolute; prefer repo-relative")
        }
      }
      checkSourcePath(agent.sourcePath, "agent")
      checkSourcePath(agenda.sourcePath, "agenda")
      checkSourcePath(agency.sourcePath, "agency")

      if !warns.isEmpty { for w in warns { print("[warn] \(w)") } }
      if !errors.isEmpty {
        for e in errors { fputs("[error] \(e)\n", stderr) }
        if strict { throw ExitCode(1) }
      } else {
        print("ok: triad valid for slug=\(slug) at \(agentsDir.path)")
      }

      let opts = CLIACore.MergeOptions(
        includeSources: withSources, includeDuplicates: showDuplicates)
      let enc = JSON.Formatting.humanEncoder
      if previewAgent {
        var v = Merger.mergeAgent(slug: slug, under: work, options: opts)
        if rootChain {
          let chain = LineageResolver.findAgentDirs(for: slug, under: work)
          v.contextChain = chain.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
        }
        let data = try enc.encode(v)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      }
      if previewAgenda {
        var v = Merger.mergeAgenda(slug: slug, under: work, options: opts)
        if rootChain {
          let chain = LineageResolver.findAgentDirs(for: slug, under: work)
          v.contextChain = chain.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
        }
        let data = try enc.encode(v)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      }
      if previewAgency {
        var v = Merger.mergeAgency(slug: slug, under: work, options: opts)
        if rootChain {
          let chain = LineageResolver.findAgentDirs(for: slug, under: work)
          v.contextChain = chain.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
        }
        let data = try enc.encode(v)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      }
    }

    // docs engine in-process parity achieved via runLocal()
  }
}

// MARK: - Mirrors

// Mirrors subcommand provided by CLIAAgentCoreCLICommands.MirrorsCommand

// MARK: - Validate Triad (presence/consistency)

extension Agents {
  struct ValidateTriad: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "validate-triad",
      abstract: "Validate presence + consistency of *.agent/agenda/agency.json per agent directory"
    )
    @Option(name: .customLong("path"), help: "Root directory (defaults to CWD)") var path: String?
    func run() async throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let fm = FileManager.default
      let e = fm.enumerator(
        at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsPackageDescendants]
      )
      var missingCount = 0
      var errorCount = 0
      var validatedDirs = Set<String>()
      while let url = e?.nextObject() as? URL {
        let p = url.path
        if !p.contains("/.clia/agents/") { continue }
        if url.lastPathComponent.hasSuffix(".agent.json"), url.hasDirectoryPath == false {
          let dir = url.deletingLastPathComponent()
          let key = dir.path
          if validatedDirs.contains(key) { continue }
          validatedDirs.insert(key)
          let contents =
            (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
          let agentURLs = contents.filter {
            $0.lastPathComponent.hasSuffix(".agent.json")
              && !$0.lastPathComponent.contains(".agency.")
          }
          let agencyURLs = contents.filter { $0.lastPathComponent.hasSuffix(".agency.json") }
          let agendaURLs = contents.filter { $0.lastPathComponent.hasSuffix(".agenda.json") }
          if agentURLs.isEmpty || agencyURLs.isEmpty || agendaURLs.isEmpty {
            var missing: [String] = []
            if agentURLs.isEmpty { missing.append("*.agent.json") }
            if agencyURLs.isEmpty { missing.append("*.agency.json") }
            if agendaURLs.isEmpty { missing.append("*.agenda.json") }
            missingCount += 1
            fputs("[error] \(dir.path): missing \(missing.joined(separator: ", "))\n", stderr)
            continue
          }
          // Lightweight slug consistency check
          let decoder = JSONDecoder()
          do {
            let a = try decoder.decode(
              CLIACoreModels.AgentDoc.self, from: Data(contentsOf: agentURLs[0]))
            let g = try decoder.decode(
              CLIACoreModels.AgendaDoc.self, from: Data(contentsOf: agendaURLs[0]))
            let y = try decoder.decode(
              CLIACoreModels.AgencyDoc.self, from: Data(contentsOf: agencyURLs[0]))
            let slug = dir.lastPathComponent
            if a.slug != slug || g.slug != slug || y.slug != slug {
              errorCount += 1
              fputs("[error] \(dir.path): slug mismatch\n", stderr)
            }
          } catch {
            errorCount += 1
            fputs("[error] \(dir.path): decode failure — \(error)\n", stderr)
          }
        }
      }
      if missingCount + errorCount > 0 { throw ExitCode(1) }
    }
  }

  struct TriadsLint: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "triads-lint",
      abstract: "Lint agent triads for required fields, S-Type contributions, and expected mixes"
    )

    @Option(name: .customLong("path"), help: "Root directory (defaults to CWD)")
    var path: String?

    func run() throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let agentsRoot = root.appendingPathComponent(".clia/agents")
      let fm = FileManager.default
      guard fm.fileExists(atPath: agentsRoot.path) else {
        throw ValidationError("No agents directory at \(agentsRoot.path)")
      }

      let spec = try STypeSpecLoader.load(root: root)
      let allowedTypes = Set(spec.types.keys)
      let decoder = JSONDecoder()
      let schemaVersions = TriadSchemaVersionSets(root: root)

      var issues: [String] = []
      issues.append(contentsOf: schemaVersions.warnings)
      let agentDirs = try fm.contentsOfDirectory(
        at: agentsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
      )
      .filter { url in
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
          && !url.lastPathComponent.hasPrefix("_")
      }

      for dir in agentDirs {
        let slug = dir.lastPathComponent
        let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        guard
          let agentURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agent.json") }),
          let agencyURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agency.json") }),
          let agendaURL = files.first(where: { $0.lastPathComponent.hasSuffix(".agenda.json") })
        else {
          issues.append("[error] \(slug): missing triad JSON files")
          continue
        }

        do {
          let agency = try decoder.decode(
            CLIACoreModels.AgencyDoc.self, from: Data(contentsOf: agencyURL))
          let agencyVersion = agency.schemaVersion.trimmingCharacters(in: .whitespacesAndNewlines)
          if !schemaVersions.agency.isEmpty && !schemaVersions.agency.contains(agencyVersion) {
            issues.append(
              "[error] \(slug) agency: schemaVersion=\(agencyVersion.isEmpty ? "<missing>" : agencyVersion) expected \(schemaVersions.describeAllowed(schema: .agency))"
            )
          }
          for entry in agency.entries {
            for group in entry.contributionGroups {
              for item in group.types {
                if item.evidence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  issues.append(
                    "[error] \(slug) agency \(entry.timestamp): missing evidence for type \(item.type)"
                  )
                }
                if !allowedTypes.contains(item.type) {
                  issues.append(
                    "[error] \(slug) agency \(entry.timestamp): unknown S-Type \(item.type)")
                }
              }
            }
          }
        } catch {
          issues.append("[error] \(slug): failed to decode agency.json — \(error)")
        }

        do {
          let agenda = try decoder.decode(
            CLIACoreModels.AgendaDoc.self, from: Data(contentsOf: agendaURL))
          let agendaVersion = agenda.schemaVersion.trimmingCharacters(in: .whitespacesAndNewlines)
          if !schemaVersions.agenda.isEmpty && !schemaVersions.agenda.contains(agendaVersion) {
            issues.append(
              "[error] \(slug) agenda: schemaVersion=\(agendaVersion.isEmpty ? "<missing>" : agendaVersion) expected \(schemaVersions.describeAllowed(schema: .agenda))"
            )
          }
          func validateExpected(_ label: String, _ expected: CLIACoreModels.ExpectedContributions?)
          {
            guard let expected else { return }
            for type in expected.types where !allowedTypes.contains(type) {
              issues.append("[error] \(slug) \(label): unknown S-Type \(type)")
            }
            if let min = expected.targets?.synergyMin, min <= 0 {
              issues.append("[warn] \(slug) \(label): synergyMin <= 0")
            }
            if let min = expected.targets?.stabilityMin, min <= 0 {
              issues.append("[warn] \(slug) \(label): stabilityMin <= 0")
            }
          }
          for item in agenda.backlog {
            validateExpected("backlog \(item.slug ?? item.title)", item.expectedContributions)
          }
          for milestone in agenda.milestones {
            validateExpected("milestone \(milestone.slug)", milestone.expectedContributions)
          }
        } catch {
          issues.append("[error] \(slug): failed to decode agenda.json — \(error)")
        }

        do {
          let agent = try decoder.decode(
            CLIACoreModels.AgentDoc.self, from: Data(contentsOf: agentURL))
          let agentVersion = agent.schemaVersion.trimmingCharacters(in: .whitespacesAndNewlines)
          if !schemaVersions.agent.isEmpty && !schemaVersions.agent.contains(agentVersion) {
            issues.append(
              "[error] \(slug) agent: schemaVersion=\(agentVersion.isEmpty ? "<missing>" : agentVersion) expected \(schemaVersions.describeAllowed(schema: .agent))"
            )
          }
        } catch {
          issues.append("[error] \(slug): failed to decode agent.json — \(error)")
        }
      }

      guard issues.isEmpty else {
        for msg in issues { fputs("\(msg)\n", stderr) }
        throw ExitCode(1)
      }
      print("ok: triads lint passed for \(agentDirs.count) agents")
    }
  }
}

// MARK: - Context (lineage chain)

// MARK: - Schema helpers

extension Agents.TriadsLint {
  private struct TriadSchemaVersionSets {
    var agent: Set<String>
    var agenda: Set<String>
    var agency: Set<String>
    var warnings: [String]

    init(root: URL) {
      var collectedWarnings: [String] = []

      func load(_ kind: TriadSchemaKind) -> Set<String> {
        do {
          return try TriadSchemaInspector.info(for: kind, root: root).allowedSchemaVersions
        } catch {
          collectedWarnings.append(
            "[warn] failed to load \(kind.displayName) schema: \(error.localizedDescription)")
          return []
        }
      }

      self.agent = load(.agent)
      self.agenda = load(.agenda)
      self.agency = load(.agency)
      self.warnings = collectedWarnings
    }

    func describeAllowed(schema kind: TriadSchemaKind) -> String {
      let values: [String]
      switch kind {
      case .agent: values = agent.sorted()
      case .agenda: values = agenda.sorted()
      case .agency: values = agency.sorted()
      case .core: values = []
      }
      return values.isEmpty ? "[any]" : values.joined(separator: ", ")
    }
  }
}

extension Agents {
  struct Context: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "context",
      abstract: "Show context chain for an agent slug (codex@sample → codex@mono → area → local)"
    )
    @Option(name: .customLong("slug")) var slug: String
    @Option(name: .customLong("path")) var path: String?
    func run() async throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let chain = LineageResolver.findAgentDirs(for: slug, under: root)
      for item in chain { print("\(item.prefix) \(item.dir.path)") }
    }
  }
}

// MARK: - Preview (merged views)

extension Agents {
  struct PreviewAgent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "preview-agent", abstract: "Preview merged agent.json across context layers")
    @Option(name: .customLong("path")) var path: String?
    @Option(name: .customLong("slug")) var slug: String
    @Flag(name: .customLong("pretty")) var pretty: Bool = false
    @Flag(name: .customLong("with-sources")) var withSources: Bool = false
    @Flag(name: .customLong("show-duplicates")) var showDuplicates: Bool = false
    @Flag(name: .customLong("root-chain")) var rootChain: Bool = false
    func run() async throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let opts = CLIACore.MergeOptions(
        includeSources: withSources, includeDuplicates: showDuplicates)
      var v = Merger.mergeAgent(slug: slug, under: root, options: opts)
      if rootChain {
        let chain = LineageResolver.findAgentDirs(for: slug, under: root)
        v.contextChain = chain.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
      }
      let enc = pretty ? JSON.Formatting.humanEncoder : JSONEncoder()
      let data = try enc.encode(v)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    }
  }
}

extension Agents {
  struct PreviewAgenda: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "preview-agenda", abstract: "Preview merged agenda.json across context layers")
    @Option(name: .customLong("path")) var path: String?
    @Option(name: .customLong("slug")) var slug: String
    @Flag(name: .customLong("pretty")) var pretty: Bool = false
    @Flag(name: .customLong("with-sources")) var withSources: Bool = false
    @Flag(name: .customLong("show-duplicates")) var showDuplicates: Bool = false
    @Flag(name: .customLong("root-chain")) var rootChain: Bool = false
    func run() async throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let opts = CLIACore.MergeOptions(
        includeSources: withSources, includeDuplicates: showDuplicates)
      var v = Merger.mergeAgenda(slug: slug, under: root, options: opts)
      if rootChain {
        let chain = LineageResolver.findAgentDirs(for: slug, under: root)
        v.contextChain = chain.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
      }
      let enc = pretty ? JSON.Formatting.humanEncoder : JSONEncoder()
      let data = try enc.encode(v)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    }
  }
}

extension Agents {
  struct PreviewAgency: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "preview-agency", abstract: "Preview merged agency.json across context layers")
    @Option(name: .customLong("path")) var path: String?
    @Option(name: .customLong("slug")) var slug: String
    @Flag(name: .customLong("pretty")) var pretty: Bool = false
    @Flag(name: .customLong("with-sources")) var withSources: Bool = false
    @Flag(name: .customLong("show-duplicates")) var showDuplicates: Bool = false
    @Flag(name: .customLong("root-chain")) var rootChain: Bool = false
    func run() async throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      let opts = CLIACore.MergeOptions(
        includeSources: withSources, includeDuplicates: showDuplicates)
      var v = Merger.mergeAgency(slug: slug, under: root, options: opts)
      if rootChain {
        let chain = LineageResolver.findAgentDirs(for: slug, under: root)
        v.contextChain = chain.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
      }
      let enc = pretty ? JSON.Formatting.humanEncoder : JSONEncoder()
      let data = try enc.encode(v)
      if let s = String(data: data, encoding: .utf8) { print(s) }
    }
  }
}

// Render agenda subcommand provided by CLIAAgentCoreCLICommands.TriadsCommandGroup.Render

// MARK: - Transfer (dry-run plan)

extension Agents {
  struct Transfer: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "transfer",
      abstract: "Dry-run or plan a safe agent transfer (move/rename)"
    )

    @Option(name: .customLong("from")) var fromPath: String
    @Option(name: .customLong("to")) var toPath: String
    @Option(name: .customLong("new-slug")) var newSlug: String?
    @Option(
      name: .customLong("include"),
      help: "Comma-separated attachments (e.g., chats,codex,summaries)") var include: String = ""
    @Flag(name: .customLong("dry-run")) var dryRun: Bool = true

    mutating func run() async throws {
      let fm = FileManager.default
      let src = URL(fileURLWithPath: fromPath)
      let dst = URL(fileURLWithPath: toPath)
      guard fm.fileExists(atPath: src.path) else {
        throw ValidationError("source not found: \(src.path)")
      }
      let srcSlug = src.lastPathComponent
      let dstSlug = dst.lastPathComponent
      let planNewSlug = newSlug ?? (dstSlug.hasPrefix("_") ? srcSlug : dstSlug)

      let repoName =
        src.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .lastPathComponent
      let triadNames = ["agent", "agency", "agenda"].map {
        "\(srcSlug)@\(repoName).\($0).json"
      }
      var triads: [[String: Any]] = []
      for name in triadNames {
        let srcTriad = src.appendingPathComponent(name)
        var entry: [String: Any] = ["source": srcTriad.path]
        if fm.fileExists(atPath: srcTriad.path) {
          if planNewSlug != srcSlug {
            let newName = name.replacingOccurrences(of: srcSlug, with: planNewSlug)
            entry["destName"] = newName
            entry["edit"] = ["slug": ["from": srcSlug, "to": planNewSlug], "updated": "now"]
          } else {
            entry["destName"] = name
            entry["edit"] = ["updated": "now"]
          }
        } else {
          entry["note"] = "missing (ok)"
        }
        triads.append(entry)
      }

      let includes = include.split(separator: ",").map { String($0) }.filter { !$0.isEmpty }
      var attachments: [[String: Any]] = []
      for inc in includes {
        let s = src.appendingPathComponent(inc)
        attachments.append(["path": s.path, "exists": fm.fileExists(atPath: s.path)])
      }
      let ts = ISO8601DateFormatter().string(from: Date())
      let receipt =
        [
          "timestamp": ts,
          "from": src.path,
          "to": dst.path,
          "slugChange": ["old": srcSlug, "new": planNewSlug],
        ] as [String: Any]
      let plan: [String: Any] = [
        "dryRun": true,
        "from": src.path,
        "to": dst.path,
        "newSlug": planNewSlug,
        "triads": triads,
        "attachments": attachments,
        "receipt": receipt,
        "notes": [
          "No filesystem changes performed (dry-run only)",
          "If destination starts with '_' (private/archive), triads may be left unchanged and audits should skip",
        ],
      ]
      let data = try JSONSerialization.data(
        withJSONObject: plan, options: [.prettyPrinted, .sortedKeys])
      if let s = String(data: data, encoding: .utf8) { print(s) }
    }
  }
}

// Journal subcommand provided by CLIAAgentCoreCLICommands.JournalCommand

// MARK: - Migrate Role

extension Agents {
  struct MigrateRole: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "migrate-role",
      abstract: "Plan (and optionally apply) a role migration across agent triads and Markdown"
    )

    @Option(name: .customLong("from")) var fromRole: String
    @Option(name: .customLong("to")) var toRole: String
    @Option(name: .customLong("path")) var path: String?
    @Flag(name: .customLong("dry-run"), help: "Print planned edits only (default)") var dryRun:
      Bool = true

    mutating func run() async throws {
      let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      print(
        "[migrate-role] plan start root=\(root.path) from=\(fromRole) to=\(toRole) dryRun=\(dryRun)"
      )
      let fm = FileManager.default
      var candidates: [URL] = []
      if let it = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) {
        while let url = it.nextObject() as? URL {
          if url.path.contains("/.build/") { continue }
          let name = url.lastPathComponent
          if name.hasSuffix(".json") || name.hasSuffix(".md") {
            if name.contains("\(fromRole).agent.") || name.contains("\(fromRole).agenda.")
              || name.contains("\(fromRole).agency.") || name.contains("\(fromRole)-")
              || name.contains("\(fromRole).")
            {
              candidates.append(url)
            }
          }
        }
      }
      if candidates.isEmpty {
        print("[migrate-role] no files referencing '\(fromRole)' found under \(root.path)")
        return
      }
      print("[migrate-role] candidates=\(candidates.count)")
      var plannedRenames: [(from: URL, to: URL)] = []
      var plannedEdits: [URL] = []
      for url in candidates.sorted(by: { $0.path < $1.path }) {
        let name = url.lastPathComponent
        let dir = url.deletingLastPathComponent()
        if name.hasSuffix(".json") {
          if name.contains(".agent.json") || name.contains(".agenda.json")
            || name.contains(".agency.json")
          {
            let comps = name.split(separator: ".").map(String.init)
            if comps.count >= 3 {
              var newName = name
              if comps[1] == fromRole {
                newName = comps[0] + "." + toRole + "." + comps[2]
                let toURL = dir.appendingPathComponent(newName)
                plannedRenames.append((from: url, to: toURL))
              }
            }
            plannedEdits.append(url)
          }
        } else if name.hasSuffix(".md") {
          if name.contains(fromRole) {
            let toName = name.replacingOccurrences(of: fromRole, with: toRole)
            let toURL = dir.appendingPathComponent(toName)
            plannedRenames.append((from: url, to: toURL))
            plannedEdits.append(url)
          }
        }
      }
      for r in plannedRenames { print("- rename: \(r.from.path) → \(r.to.path)") }
      for e in plannedEdits { print("- edit:   \(e.path)") }
      guard !dryRun else {
        print("[migrate-role] dry-run complete — no changes applied.")
        return
      }
      for r in plannedRenames {
        try? fm.createDirectory(
          at: r.to.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? fm.removeItem(at: r.to)
        try fm.moveItem(at: r.from, to: r.to)
      }
      for url in plannedEdits {
        if url.path.hasSuffix(".json") {
          do {
            let data = try Data(contentsOf: url)
            let name = url.lastPathComponent
            if name.contains(".agent.json") {
              var doc = try JSONDecoder().decode(AgentDoc.self, from: data)
              // For AgentDoc, slug is canonical; migrate by slug when matching.
              if doc.slug == fromRole { doc.slug = toRole }
              if doc.slug == fromRole { doc.slug = toRole }
              if let xsrc = doc.sourcePath, xsrc.contains(fromRole) {
                doc.sourcePath = xsrc.replacingOccurrences(of: fromRole, with: toRole)
              }
              try JSON.FileWriter.write(doc, to: url, encoder: JSON.Formatting.humanEncoder)
            } else if name.contains(".agenda.json") {
              var doc = try JSONDecoder().decode(AgendaDoc.self, from: data)
              if doc.agent.role == fromRole { doc.agent.role = toRole }
              if doc.slug == fromRole { doc.slug = toRole }
              if let xsrc = doc.sourcePath, xsrc.contains(fromRole) {
                doc.sourcePath = xsrc.replacingOccurrences(of: fromRole, with: toRole)
              }
              try JSON.FileWriter.write(doc, to: url, encoder: JSON.Formatting.humanEncoder)
            } else if name.contains(".agency.json") {
              var doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
              if doc.slug == fromRole { doc.slug = toRole }
              if let xsrc = doc.sourcePath, xsrc.contains(fromRole) {
                doc.sourcePath = xsrc.replacingOccurrences(of: fromRole, with: toRole)
              }
              try JSON.FileWriter.write(doc, to: url, encoder: JSON.Formatting.humanEncoder)
            }
          } catch {
            fputs("[migrate-role] warn: failed to edit JSON at \(url.path): \(error)\n", stderr)
          }
        } else if url.path.hasSuffix(".md") {
          if var s = try? String(contentsOf: url, encoding: .utf8) {
            s = s.replacingOccurrences(of: fromRole, with: toRole)
            try? s.write(to: url, atomically: true, encoding: .utf8)
          }
        }
      }
      print(
        "[migrate-role] apply complete — renames=\(plannedRenames.count) edits=\(plannedEdits.count)"
      )
    }
  }
}

// MARK: - Migrate Agency Contributions (legacy → grouped)

extension Agents {
  struct MigrateAgencyContributions: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "migrate-agency-contributions",
      abstract: "Lift legacy agency contributions to grouped, evidenced form"
    )

    @Option(
      name: .customLong("agents-dir"), help: "Agents root directory (default: .clia/agents)"
    )
    var agentsDir: String = ".clia/agents"

    @Option(name: .customLong("slug"), parsing: .upToNextOption, help: "Limit to agent slug(s)")
    var slugs: [String] = []

    @Flag(name: .customLong("dry-run"), help: "Show planned edits; do not write")
    var dryRun: Bool = false

    func run() throws {
      let root = URL(fileURLWithPath: agentsDir)
      let fm = FileManager.default
      guard fm.fileExists(atPath: root.path) else {
        throw ValidationError("agents dir not found: \(root.path)")
      }
      var dirs = try fm.contentsOfDirectory(
        at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
      ).filter { url in
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
      }
      if !slugs.isEmpty { dirs = dirs.filter { slugs.contains($0.lastPathComponent) } }
      var filesChanged = 0
      for dir in dirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        let slug = dir.lastPathComponent
        guard
          let agencyURL = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .first(where: { $0.lastPathComponent.hasSuffix(".agency.json") })
        else { continue }
        let data = try Data(contentsOf: agencyURL)
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
          continue
        }
        var changedCount = 0
        if let entries = root["entries"] as? [Any] {
          var newEntries: [Any] = []
          for any in entries {
            guard var d = any as? [String: Any] else {
              newEntries.append(any)
              continue
            }
            // Only transform journal entries (those with timestamp)
            guard d["timestamp"] is String else {
              newEntries.append(d)
              continue
            }
            // Inspect contributions
            guard let contribAny = d["contributions"] as? [Any], !contribAny.isEmpty else {
              newEntries.append(d)
              continue
            }
            // If already grouped (objects with "by" and "types"), skip
            let looksGrouped: Bool = (contribAny.first as? [String: Any])?["types"] != nil
            if looksGrouped {
              newEntries.append(d)
              continue
            }
            // Expect legacy [String]
            let flat: [String] = contribAny.compactMap { $0 as? String }.filter { !$0.isEmpty }
            if flat.isEmpty {
              newEntries.append(d)
              continue
            }
            let actors: [String] = {
              if let parts = d["participants"] as? [String], !parts.isEmpty { return parts }
              return [slug]
            }()
            let items: [[String: Any]] = flat.map {
              ["type": $0, "weight": 1.0, "evidence": "migrated"]
            }
            let groups: [[String: Any]] = actors.map { ["by": $0, "types": items] }
            d["contributions"] = groups
            d.removeValue(forKey: "participants")
            newEntries.append(d)
            changedCount += 1
          }
          if changedCount > 0 {
            root["entries"] = newEntries
            filesChanged += 1
            if dryRun {
              print("would write \(agencyURL.path) — entries migrated: \(changedCount)")
            } else {
              try JSON.FileWriter.writeJSONObject(
                root, to: agencyURL, options: JSON.Formatting.humanOptions, atomic: true)
              print("migrated \(agencyURL.path) — entries: \(changedCount)")
            }
          }
        }
      }
      if filesChanged == 0 { print("no changes (already grouped or empty)") }
    }
  }
}

// Roster-update subcommand provided by CLIAAgentCoreCLICommands.RosterUpdateCommand

// Render agenda subcommand provided by CLIAAgentCoreCLICommands.TriadsCommandGroup.Render
