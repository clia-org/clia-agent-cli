import CLIAAgentCoreCLICommands
import CLIACore
import CLIACoreModels
import Foundation

public enum CLIAAgentAudit {
  public static let auditSchemaVersion: String = "1.0.0"

  public static func auditAgents(
    at root: URL,
    options: AuditOptions = .init(engine: .local)
  ) throws -> AgentAuditResult {
    switch options.engine {
    case .local:
      return try LocalEngine().run(at: root, options: options)
    case .docs:
      throw AuditError.docsEngineUnavailable
    }
  }

  public static func auditAgent(
    slug: String,
    at root: URL,
    options: AuditOptions = .init(engine: .local)
  ) throws -> AgentAuditResult {
    let full = try auditAgents(at: root, options: options)
    let filteredChecks = full.checks.filter { check in
      if check.id.hasPrefix("agent-") {
        return check.id.contains("agent-\(slug)-")
      }
      // keep repo-level checks
      return check.id == "clia-stack" || check.id == "agents-stack"
        || check.id == "agents-roster"
    }
    return AgentAuditResult(
      schemaVersion: full.schemaVersion,
      root: full.root,
      timestamp: full.timestamp,
      agents: full.agents.filter { $0 == slug },
      checks: filteredChecks
    )
  }
}

// MARK: - Local Engine

private struct LocalEngine {
  func run(at root: URL, options: AuditOptions) throws -> AgentAuditResult {
    let fm = FileManager.default
    guard fm.fileExists(atPath: root.path) else {
      throw AuditError.pathNotFound(root)
    }
    let cliaRoot = root.appendingPathComponent(".clia")
    let agentsRoot = cliaRoot.appendingPathComponent("agents")
    let rosterURL = root.appendingPathComponent("AGENTS.md")

    var checks: [AgentAuditCheck] = []

    let schemaVersions = TriadSchemaVersionSets(root: root)
    // Repo-level: clia-stack
    let hasCliaRoot = fm.fileExists(atPath: cliaRoot.path)
    checks.append(
      AgentAuditCheck(
        id: "clia-stack",
        title: "CLIA stack present",
        level: .blocking,
        status: hasCliaRoot ? .pass : .fail,
        message: hasCliaRoot
          ? "Found .clia" : "Missing .clia directory"
      )
    )

    // Repo-level: agents-stack
    let hasAgentsDir = fm.fileExists(atPath: agentsRoot.path)
    var agentDirs: [URL] = []
    var rosterText = ""
    var slugs: [String] = []
    if hasAgentsDir {
      if let contents = try? fm.contentsOfDirectory(
        at: agentsRoot,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      ) {
        agentDirs = contents.filter { url in
          var isDir: ObjCBool = false
          return fm.fileExists(atPath: url.path, isDirectory: &isDir)
            && isDir.boolValue
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
      }
    }
    if !hasAgentsDir {
      checks.append(
        AgentAuditCheck(
          id: "agents-stack",
          title: "CLIA agents present",
          level: .blocking,
          status: .fail,
          message: "Missing .clia/agents directory"
        )
      )
    } else if agentDirs.isEmpty {
      checks.append(
        AgentAuditCheck(
          id: "agents-stack",
          title: "CLIA agents present",
          level: .blocking,
          status: .fail,
          message: "No agents found under .clia/agents"
        )
      )
    } else {
      checks.append(
        AgentAuditCheck(
          id: "agents-stack",
          title: "CLIA agents present",
          level: .blocking,
          status: .pass,
          message: "Found \(agentDirs.count) agent(s)"
        )
      )
      if schemaVersions.warnings.isEmpty {
        checks.append(
          AgentAuditCheck(
            id: "triads-schemas",
            title: "Triad schemas resolved",
            level: .advisory,
            status: .pass,
            message: schemaVersions.describeSources()
          )
        )
      } else {
        checks.append(
          AgentAuditCheck(
            id: "triads-schemas",
            title: "Triad schemas resolved",
            level: .advisory,
            status: .warn,
            message: schemaVersions.warnings.joined(separator: "; ")
          )
        )
      }

      // Repo-level: agents-roster
      let rosterExists = fm.fileExists(atPath: rosterURL.path)
      let rosterValue =
        (try? String(contentsOf: rosterURL, encoding: .utf8)) ?? ""
      rosterText = rosterValue
      let rosterTrimmed = rosterValue.trimmingCharacters(
        in: .whitespacesAndNewlines
      )
      let rosterStatus: AuditStatus
      let rosterMessage: String
      if !rosterExists {
        rosterStatus = .warn
        rosterMessage = "AGENTS.md missing"
      } else if rosterTrimmed.isEmpty {
        rosterStatus = .warn
        rosterMessage = "AGENTS.md is empty"
      } else {
        rosterStatus = .pass
        rosterMessage = "Roster lists commissioned agents (CLIA)"
      }
      checks.append(
        AgentAuditCheck(
          id: "agents-roster",
          title: "Agent roster",
          level: .advisory,
          status: rosterStatus,
          message: rosterMessage
        )
      )

      // Per-agent checks
      slugs = agentDirs.map { $0.lastPathComponent }
      for dir in agentDirs {
        checks.append(
          contentsOf: checkAgent(
            at: dir,
            repoRoot: root,
            roster: rosterText,
            schemaVersions: schemaVersions
          )
        )
      }
    }

    // Filter by includeIDs if provided
    let finalChecks: [AgentAuditCheck] = {
      if let ids = options.includeIDs, !ids.isEmpty {
        return checks.filter { ids.contains($0.id) }
      }
      return checks
    }()

    let nowISO: String = {
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return f.string(from: Date())
    }()

    return AgentAuditResult(
      schemaVersion: CLIAAgentAudit.auditSchemaVersion,
      root: root.path,
      timestamp: nowISO,
      agents: slugs,
      checks: finalChecks
    )
  }

  func checkAgent(
    at dir: URL,
    repoRoot: URL,
    roster: String,
    schemaVersions: TriadSchemaVersionSets
  ) -> [AgentAuditCheck] {
    var checks: [AgentAuditCheck] = []
    let fm = FileManager.default
    let slug = dir.lastPathComponent
    let repoRoot =
      dir
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    // Files (mirrors)
    let required = [".agent.md", ".agenda.md", ".agency.md"].map {
      "\(slug)\($0)"
    }
    var missing: [String] = []
    var slugHeaderMismatch = false
    for name in required {
      let url = dir.appendingPathComponent(name)
      if !fm.fileExists(atPath: url.path) {
        missing.append(name)
        continue
      }
      if name.hasSuffix(".agent.md") {
        if let text = try? String(contentsOf: url, encoding: .utf8) {
          if !text.contains("> Slug: `\(slug)`") { slugHeaderMismatch = true }
        }
      }
    }
    let filesStatus: AuditStatus =
      (missing.isEmpty && !slugHeaderMismatch) ? .pass : .fail
    let filesMessage: String = {
      var parts: [String] = []
      if !missing.isEmpty {
        parts.append("Missing " + missing.joined(separator: ", "))
      }
      if slugHeaderMismatch {
        parts.append("Slug header mismatch in \(slug).agent.md")
      }
      return parts.isEmpty
        ? "All required agent documents present" : parts.joined(separator: "; ")
    }()
    checks.append(
      AgentAuditCheck(
        id: "agent-\(slug)-files",
        title: "Agent \(slug) files",
        level: .blocking,
        status: filesStatus,
        message: filesMessage,
        slug: slug
      )
    )

    // Placeholders in mirrors
    let phrases: Set<String> = placeholderPhrases
    var hits: Set<String> = []
    for name in required {
      let url = dir.appendingPathComponent(name)
      if let text = try? String(contentsOf: url, encoding: .utf8) {
        for p in phrases where text.contains(p) { hits.insert(p) }
      }
    }
    let phStatus: AuditStatus = hits.isEmpty ? .pass : .warn
    let phMsg =
      hits.isEmpty
      ? "No template placeholders remain"
      : ("Replace placeholder text: " + hits.sorted().joined(separator: "; "))
    checks.append(
      AgentAuditCheck(
        id: "agent-\(slug)-placeholders",
        title: "Agent \(slug) placeholders",
        level: .advisory,
        status: phStatus,
        message: phMsg,
        slug: slug
      )
    )

    // JSON triads
    let files =
      (try? fm.contentsOfDirectory(
        at: dir,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )) ?? []
    func find(_ suffix: String) -> URL? {
      files.first(where: { $0.lastPathComponent.hasSuffix(suffix) })
    }
    let agentJSON = find(".agent.json")
    let agendaJSON = find(".agenda.json")
    let agencyJSON = find(".agency.json")
    var jsonMissing: [String] = []
    if agentJSON == nil { jsonMissing.append("*.agent.json") }
    if agendaJSON == nil { jsonMissing.append("*.agenda.json") }
    if agencyJSON == nil { jsonMissing.append("*.agency.json") }
    let jsonStatus: AuditStatus = jsonMissing.isEmpty ? .pass : .warn
    let jsonMsg =
      jsonMissing.isEmpty
      ? "Agent JSON triads present"
      : ("Missing JSON: " + jsonMissing.joined(separator: ", "))
    checks.append(
      AgentAuditCheck(
        id: "agent-\(slug)-json",
        title: "Agent \(slug) JSON triads",
        level: .advisory,
        status: jsonStatus,
        message: jsonMsg,
        slug: slug
      )
    )

    // JSON core fields
    if let agentURL = agentJSON, let data = try? Data(contentsOf: agentURL),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
      if let typedAgent = try? JSONDecoder().decode(
        CLIACoreModels.AgentDoc.self,
        from: data
      ) {
        let version = typedAgent.schemaVersion.trimmingCharacters(
          in: .whitespacesAndNewlines
        )
        if !schemaVersions.agent.versions.isEmpty
          && !schemaVersions.agent.versions.contains(version)
        {
          checks.append(
            AgentAuditCheck(
              id: "agent-\(slug)-schema-version",
              title: "Agent \(slug) schema version",
              level: .advisory,
              status: .warn,
              message:
                "schemaVersion=\(version.isEmpty ? "<missing>" : version) expected \(schemaVersions.describeAllowed(for: .agent))",
              slug: slug
            )
          )
        }
      }
      // Forbidden legacy keys should not be present in AgentDoc going forward
      do {
        let forbidden: [String] = [
          "responseHeader", "callSign", "x-callSign", "agentSlug",
        ]
        var hits: [String] = []
        for key in forbidden where obj.keys.contains(key) { hits.append(key) }
        let fkStatus: AuditStatus = hits.isEmpty ? .pass : .fail
        let fkMsg =
          hits.isEmpty
          ? "No forbidden legacy keys present"
          : ("Remove legacy keys from agent triad: "
            + hits.sorted().joined(separator: ", "))
        checks.append(
          AgentAuditCheck(
            id: "agent-\(slug)-forbidden-keys",
            title: "Agent \(slug) forbidden fields",
            level: .blocking,
            status: fkStatus,
            message: fkMsg,
            slug: slug
          )
        )
      }

      // Role must be present and non-empty (schema requires field; enforce content)
      do {
        let roleVal =
          (obj["role"] as? String)?.trimmingCharacters(
            in: .whitespacesAndNewlines
          ) ?? ""
        let rStatus: AuditStatus = roleVal.isEmpty ? .fail : .pass
        let rMsg =
          roleVal.isEmpty
          ? "Missing or empty role field" : "Role present: \(roleVal)"
        checks.append(
          AgentAuditCheck(
            id: "agent-\(slug)-role",
            title: "Agent \(slug) role",
            level: .blocking,
            status: rStatus,
            message: rMsg,
            slug: slug
          )
        )
      }

      let purposeOK =
        (obj["purpose"] as? String)?.trimmingCharacters(
          in: .whitespacesAndNewlines
        ).isEmpty
        == false
      let respOK = (obj["responsibilities"] as? [Any])?.isEmpty == false
      let guardsOK = (obj["guardrails"] as? [Any])?.isEmpty == false
      var missingCore: [String] = []
      if !purposeOK { missingCore.append("purpose") }
      if !respOK { missingCore.append("responsibilities") }
      if !guardsOK { missingCore.append("guardrails") }
      let coreStatus: AuditStatus = missingCore.isEmpty ? .pass : .warn
      let coreMsg =
        missingCore.isEmpty
        ? "purpose, responsibilities, guardrails present"
        : ("Missing: " + missingCore.joined(separator: ", "))
      checks.append(
        AgentAuditCheck(
          id: "agent-\(slug)-json-core",
          title: "Agent \(slug) JSON core fields",
          level: .advisory,
          status: coreStatus,
          message: coreMsg,
          slug: slug
        )
      )
    }

    // Agency contributions (evidence + types)
    if let agencyURL = agencyJSON, let data = try? Data(contentsOf: agencyURL) {
      if let agency = try? JSONDecoder().decode(
        CLIACoreModels.AgencyDoc.self,
        from: data
      ) {
        let version = agency.schemaVersion.trimmingCharacters(
          in: .whitespacesAndNewlines
        )
        if !schemaVersions.agency.versions.isEmpty
          && !schemaVersions.agency.versions.contains(version)
        {
          checks.append(
            AgentAuditCheck(
              id: "agent-\(slug)-agency-schema-version",
              title: "Agent \(slug) agency schema version",
              level: .advisory,
              status: .warn,
              message:
                "schemaVersion=\(version.isEmpty ? "<missing>" : version) expected \(schemaVersions.describeAllowed(for: .agency))",
              slug: slug
            )
          )
        }
        let allowed: Set<String> = {
          guard let spec = try? STypeSpecLoader.load(root: repoRoot) else {
            return []
          }
          return Set(spec.types.keys)
        }()
        var missingEvidence = 0
        var unknown: Set<String> = []
        for e in agency.entries {
          let groups = e.contributionGroups
          for g in groups {
            for item in g.types {
              if item.evidence.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
              {
                missingEvidence += 1
              }
              if !allowed.isEmpty && !allowed.contains(item.type) {
                unknown.insert(item.type)
              }
            }
          }
        }
        let hasIssues = missingEvidence > 0 || !unknown.isEmpty
        let status: AuditStatus = hasIssues ? .fail : .pass
        var msgParts: [String] = []
        if missingEvidence > 0 {
          msgParts.append("missing evidence x\(missingEvidence)")
        }
        if !unknown.isEmpty {
          msgParts.append(
            "unknown types: \(unknown.sorted().joined(separator: ", "))"
          )
        }
        let msg =
          msgParts.isEmpty
          ? "Agency contributions valid" : msgParts.joined(separator: "; ")
        checks.append(
          AgentAuditCheck(
            id: "agent-\(slug)-agency-contributions",
            title: "Agent \(slug) agency contributions",
            level: .blocking,
            status: status,
            message: msg,
            slug: slug
          )
        )
      }
    }

    // Agenda notes present (schema 0.3.0: notes is an array of Note objects with blocks)
    if let agendaURL = agendaJSON, let data = try? Data(contentsOf: agendaURL),
      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
      if let typedAgenda = try? JSONDecoder().decode(
        CLIACoreModels.AgendaDoc.self,
        from: data
      ) {
        let version = typedAgenda.schemaVersion.trimmingCharacters(
          in: .whitespacesAndNewlines
        )
        if !schemaVersions.agenda.versions.isEmpty
          && !schemaVersions.agenda.versions.contains(version)
        {
          checks.append(
            AgentAuditCheck(
              id: "agent-\(slug)-agenda-schema-version",
              title: "Agent \(slug) agenda schema version",
              level: .advisory,
              status: .warn,
              message:
                "schemaVersion=\(version.isEmpty ? "<missing>" : version) expected \(schemaVersions.describeAllowed(for: .agenda))",
              slug: slug
            )
          )
        }
      }
      let notesOK: Bool = {
        // 0.3.0: notes is an array; any note with non-empty blocks passes
        if let notesArr = obj["notes"] as? [Any] {
          for n in notesArr {
            if let nd = n as? [String: Any],
              let blocks = nd["blocks"] as? [Any], !blocks.isEmpty
            {
              return true
            }
          }
          return false
        }
        // Legacy fallback (object with blocks)
        if let notesObj = obj["notes"] as? [String: Any],
          let blocks = notesObj["blocks"] as? [Any],
          !blocks.isEmpty
        {
          return true
        }
        return false
      }()
      let nStatus: AuditStatus = notesOK ? .pass : .warn
      let nMsg =
        notesOK ? "Agenda notes present" : "Agenda notes missing or empty"
      checks.append(
        AgentAuditCheck(
          id: "agent-\(slug)-json-notes",
          title: "Agent \(slug) agenda notes",
          level: .advisory,
          status: nStatus,
          message: nMsg,
          slug: slug
        )
      )
    }

    // Roster token contains path
    if !roster.isEmpty {
      let token = "`.clia/agents/\(slug)/`"
      let rStatus: AuditStatus
      let rMsg: String
      if roster.contains(token) {
        rStatus = .pass
        rMsg = "Roster lists .clia/agents/\(slug)/"
      } else {
        rStatus = .warn
        rMsg = "Add .clia/agents/\(slug)/ to AGENTS.md"
      }
      checks.append(
        AgentAuditCheck(
          id: "agent-\(slug)-roster",
          title: "Agent \(slug) roster entry",
          level: .advisory,
          status: rStatus,
          message: rMsg,
          slug: slug
        )
      )
    } else {
      checks.append(
        AgentAuditCheck(
          id: "agent-\(slug)-roster",
          title: "Agent \(slug) roster entry",
          level: .advisory,
          status: .skip,
          message: "AGENTS.md missing",
          slug: slug
        )
      )
    }

    return checks
  }

  var placeholderPhrases: Set<String> {
    [
      "Describe this agent's purpose. Tie it back to the DocC mission article for the app or library.",
      "List core strengths or tools.",
      "Mention any guardrails or scope boundaries.",
      "Outline how the agent begins a session.",
      "Capture checkpoints (for example, sync with CLIA timers).",
      "Document how the agent closes the loop.",
      "Specify when humans or other agents must be notified.",
      "Summarize the daily objective.",
      "Describe a longer-horizon review.",
      "Capture triggers for special sessions.",
      "Seed the first initiative.",
      "Add another action item.",
      "Reference other agents, services, or data feeds.",
      "Record achievements, deliverables, or escalations.",
      "Outline what the agent should tackle next.",
      "Sources/<Module>.docc/TheMission.md",
    ]
  }
}

// MARK: - Public Types

private struct TriadSchemaVersionSets {
  struct Entry {
    var versions: Set<String>
    var source: TriadSchemaSource?
  }

  var agent: Entry
  var agenda: Entry
  var agency: Entry
  var warnings: [String]

  init(root: URL) {
    var collectedWarnings: [String] = []

    func load(_ kind: TriadSchemaKind) -> Entry {
      do {
        let info = try TriadSchemaInspector.info(for: kind, root: root)
        return Entry(versions: info.allowedSchemaVersions, source: info.source)
      } catch {
        collectedWarnings.append(
          "Failed to load \(kind.displayName) schema: \(error.localizedDescription)"
        )
        return Entry(versions: [], source: nil)
      }
    }

    self.agent = load(.agent)
    self.agenda = load(.agenda)
    self.agency = load(.agency)
    self.warnings = collectedWarnings
  }

  func describeSources() -> String {
    var parts: [String] = []
    if let source = agent.source { parts.append("agent=\(source.describe())") }
    if let source = agenda.source {
      parts.append("agenda=\(source.describe())")
    }
    if let source = agency.source {
      parts.append("agency=\(source.describe())")
    }
    return parts.isEmpty
      ? "Triad schemas resolved" : parts.joined(separator: "; ")
  }

  func describeAllowed(for kind: TriadSchemaKind) -> String {
    let values: [String]
    switch kind {
    case .agent: values = agent.versions.sorted()
    case .agenda: values = agenda.versions.sorted()
    case .agency: values = agency.versions.sorted()
    case .core: values = []
    }
    return values.isEmpty ? "[any]" : values.joined(separator: ", ")
  }
}

extension TriadSchemaSource {
  fileprivate func describe() -> String {
    switch self {
    case .bundle:
      return "bundle"
    case .override(let url):
      return "override(\(url.path))"
    }
  }
}

public struct AuditOptions: Sendable {
  public var engine: Engine
  public var includeIDs: Set<String>?
  public var agentsOnly: Bool
  public var withSources: Bool
  public var showDuplicates: Bool
  public var rootChain: Bool
  public init(
    engine: Engine = .local,
    includeIDs: Set<String>? = nil,
    agentsOnly: Bool = true,
    withSources: Bool = false,
    showDuplicates: Bool = false,
    rootChain: Bool = false
  ) {
    self.engine = engine
    self.includeIDs = includeIDs
    self.agentsOnly = agentsOnly
    self.withSources = withSources
    self.showDuplicates = showDuplicates
    self.rootChain = rootChain
  }
}

public enum Engine: String, Sendable, Codable { case local, docs }

public struct AgentAuditCheck: Sendable, Codable {
  public var id: String
  public var title: String
  public var level: AuditLevel
  public var status: AuditStatus
  public var message: String
  public var base: Double?
  public var penalty: Int?
  public var slug: String?
  public init(
    id: String,
    title: String,
    level: AuditLevel,
    status: AuditStatus,
    message: String,
    base: Double? = nil,
    penalty: Int? = nil,
    slug: String? = nil
  ) {
    self.id = id
    self.title = title
    self.level = level
    self.status = status
    self.message = message
    self.base = base
    self.penalty = penalty
    self.slug = slug
  }
}

public struct AgentAuditResult: Sendable, Codable {
  public var schemaVersion: String
  public var root: String
  public var timestamp: String
  public var agents: [String]
  public var checks: [AgentAuditCheck]
  public init(
    schemaVersion: String,
    root: String,
    timestamp: String,
    agents: [String],
    checks: [AgentAuditCheck]
  ) {
    self.schemaVersion = schemaVersion
    self.root = root
    self.timestamp = timestamp
    self.agents = agents
    self.checks = checks
  }
}

public enum AuditLevel: String, Sendable, Codable { case blocking, advisory }
public enum AuditStatus: String, Sendable, Codable {
  case pass, fail, warn, skip
}

public enum AuditError: Error, Sendable, CustomStringConvertible {
  case pathNotFound(URL)
  case invalidAgentsLayout(String)
  case docsEngineUnavailable
  case internalError(String)
  public var description: String {
    switch self {
    case .pathNotFound(let url): return "path not found: \(url.path)"
    case .invalidAgentsLayout(let msg): return "invalid agents layout: \(msg)"
    case .docsEngineUnavailable: return "docs engine unavailable"
    case .internalError(let msg): return "internal error: \(msg)"
    }
  }
}
