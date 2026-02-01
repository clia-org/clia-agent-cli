import Foundation

public struct AgentDoc: Codable, Sendable {
  public var schemaVersion: String
  public var slug: String
  public var title: String
  public var updated: String
  public var status: String?
  // Agent identity is represented by `slug`; no separate alias field
  // Display identity (profiles only; not used for mentions)
  public var role: String?
  // Inheritance: top-level optional list of file paths or HTTP(S) URLs
  public var inherits: [String]?
  // Optional repo-relative path to human-authored source (e.g., Markdown)
  public var sourcePath: String?
  // Optional repo-relative path to avatar asset (e.g., DocC + CLI output)
  public var avatarPath: String?
  // Optional Figlet font name for agent banner rendering
  public var figletFontName: String?
  public var mentors: [String]
  public var tags: [String]
  public var links: [LinkRef]
  public var purpose: String?
  public var responsibilities: [String]
  public var guardrails: [String]
  public var checklists: [Checklist]
  public var sections: [Section]
  public var notes: [Note]
  public var extensions: [String: ExtensionValue]?
  // Core classification fields (All‑Contributors aligned)
  public var emojiTags: [String] = []
  // Weighted defaults for contribution roles (primary required when present; secondary optional)
  public var contributionMix: ContributionMix? = nil
  // Focus domains (areas/initiatives the agent focuses on)
  public var focusDomains: [FocusDomain]? = nil
  // System-instructions and persona (schema 0.4.0 core)
  public var persona: PersonaRefs? = nil
  public var systemInstructions: SystemInstructionsRefs? = nil
  public var cliSpec: CLISpecExport? = nil

  public init(
    schemaVersion: String = TriadSchemaVersion.current,
    slug: String,
    title: String,
    updated: String,
    status: String? = nil,
    role: String? = nil,
    inherits: [String]? = nil,
    sourcePath: String? = nil,
    avatarPath: String? = nil,
    figletFontName: String? = nil,
    mentors: [String] = [],
    tags: [String] = [],
    links: [LinkRef] = [],
    purpose: String? = nil,
    responsibilities: [String] = [],
    guardrails: [String] = [],
    checklists: [Checklist] = [],
    sections: [Section] = [],
    notes: [Note] = [],
    extensions: [String: ExtensionValue]? = nil,
    emojiTags: [String] = [],
    contributionMix: ContributionMix? = nil,
    focusDomains: [FocusDomain]? = nil,
    persona: PersonaRefs? = nil,
    systemInstructions: SystemInstructionsRefs? = nil,
    cliSpec: CLISpecExport? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.slug = slug
    self.title = title
    self.updated = updated
    self.status = status
    self.role = role
    self.inherits = inherits
    self.sourcePath = sourcePath
    self.avatarPath = avatarPath
    self.figletFontName = figletFontName
    self.mentors = mentors
    self.tags = tags
    self.links = links
    self.purpose = purpose
    self.responsibilities = responsibilities
    self.guardrails = guardrails
    self.checklists = checklists
    self.sections = sections
    self.notes = notes
    self.extensions = extensions
    self.emojiTags = emojiTags
    self.contributionMix = contributionMix
    self.focusDomains = focusDomains
    self.persona = persona
    self.systemInstructions = systemInstructions
    self.cliSpec = cliSpec
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case slug
    case title
    case updated
    case status
    case role  // display role (profiles)
    case inherits
    case sourcePath
    case avatarPath
    case figletFontName
    case mentors
    case tags
    case links
    case purpose
    case responsibilities
    case guardrails
    case checklists
    case sections
    case notes
    case extensions
    case emojiTags
    case contributionMix
    case focusDomains
    case persona
    case systemInstructions
    case cliSpec
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let decodedSchemaVersion = try c.decode(String.self, forKey: .schemaVersion)
    guard decodedSchemaVersion == TriadSchemaVersion.current else {
      throw DecodingError.dataCorruptedError(
        forKey: .schemaVersion,
        in: c,
        debugDescription: "Expected schemaVersion \(TriadSchemaVersion.current)"
      )
    }
    self.schemaVersion = decodedSchemaVersion
    self.slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
    self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    self.updated = try c.decodeIfPresent(String.self, forKey: .updated) ?? ""
    self.status = try c.decodeIfPresent(String.self, forKey: .status)
    // Decode display role from top-level "role"
    if let disp = try c.decodeIfPresent(String.self, forKey: .role) {
      self.role = disp
    } else {
      self.role = nil
    }
    self.inherits = try c.decodeIfPresent([String].self, forKey: .inherits)
    self.sourcePath = try c.decodeIfPresent(String.self, forKey: .sourcePath)
    self.avatarPath = try c.decodeIfPresent(String.self, forKey: .avatarPath)
    self.figletFontName = try c.decodeIfPresent(String.self, forKey: .figletFontName)
    if let ms = try c.decodeIfPresent([String].self, forKey: .mentors) {
      self.mentors = ms
    } else if let pref = try c.decodeIfPresent([PersonRef].self, forKey: .mentors) {
      self.mentors = pref.map { $0.name }
    } else {
      self.mentors = []
    }
    self.tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    self.links = try c.decodeIfPresent([LinkRef].self, forKey: .links) ?? []
    self.purpose = try c.decodeIfPresent(String.self, forKey: .purpose)
    self.responsibilities = try c.decodeIfPresent([String].self, forKey: .responsibilities) ?? []
    self.guardrails = try c.decodeIfPresent([String].self, forKey: .guardrails) ?? []
    if let typedCL = try c.decodeIfPresent([Checklist].self, forKey: .checklists) {
      self.checklists = typedCL
    } else if let flatCL = try? c.decodeIfPresent([String].self, forKey: .checklists) {
      self.checklists = [Checklist(title: nil, items: flatCL.map { ChecklistItem(text: $0) })]
    } else {
      self.checklists = []
    }
    if let typedSec = try c.decodeIfPresent([Section].self, forKey: .sections) {
      self.sections = typedSec
    } else if let flatSec = try? c.decodeIfPresent([String].self, forKey: .sections) {
      self.sections = AgentDoc.sectionsFromFlat(flatSec)
    } else {
      self.sections = []
    }
    self.notes = try c.decodeIfPresent([Note].self, forKey: .notes) ?? []
    self.extensions = try c.decodeIfPresent([String: ExtensionValue].self, forKey: .extensions)
    self.emojiTags = try c.decodeIfPresent([String].self, forKey: .emojiTags) ?? []
    self.contributionMix = try c.decodeIfPresent(ContributionMix.self, forKey: .contributionMix)
    self.focusDomains = try c.decodeIfPresent([FocusDomain].self, forKey: .focusDomains)
    self.persona = try c.decodeIfPresent(PersonaRefs.self, forKey: .persona)
    self.systemInstructions = try c.decodeIfPresent(
      SystemInstructionsRefs.self, forKey: .systemInstructions)
    self.cliSpec = try c.decodeIfPresent(CLISpecExport.self, forKey: .cliSpec)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(schemaVersion, forKey: .schemaVersion)
    try c.encode(slug, forKey: .slug)
    try c.encode(title, forKey: .title)
    try c.encode(updated, forKey: .updated)
    try c.encodeIfPresent(status, forKey: .status)
    try c.encodeIfPresent(role, forKey: .role)
    try c.encodeIfPresent(inherits, forKey: .inherits)
    try c.encodeIfPresent(sourcePath, forKey: .sourcePath)
    try c.encodeIfPresent(avatarPath, forKey: .avatarPath)
    try c.encodeIfPresent(figletFontName, forKey: .figletFontName)
    try c.encode(mentors, forKey: .mentors)
    try c.encode(tags, forKey: .tags)
    try c.encode(links, forKey: .links)
    try c.encodeIfPresent(purpose, forKey: .purpose)
    try c.encode(responsibilities, forKey: .responsibilities)
    try c.encode(guardrails, forKey: .guardrails)
    try c.encode(checklists, forKey: .checklists)
    try c.encode(sections, forKey: .sections)
    try c.encode(notes, forKey: .notes)
    try c.encodeIfPresent(extensions, forKey: .extensions)
    try c.encode(emojiTags, forKey: .emojiTags)
    try c.encodeIfPresent(contributionMix, forKey: .contributionMix)
    try c.encodeIfPresent(focusDomains, forKey: .focusDomains)
    try c.encodeIfPresent(persona, forKey: .persona)
    try c.encodeIfPresent(systemInstructions, forKey: .systemInstructions)
    try c.encodeIfPresent(cliSpec, forKey: .cliSpec)
  }

  public static func sectionsFromFlat(_ arr: [String]) -> [Section] {
    var titled: [String: [String]] = [:]
    var untitled: [String] = []
    for s in arr {
      if let r = s.range(of: ": ") {
        let t = String(s[..<r.lowerBound])
        let item = String(s[r.upperBound...])
        titled[t, default: []].append(item)
      } else {
        untitled.append(s)
      }
    }
    var out: [Section] = titled.map { Section(title: $0.key, items: $0.value) }
    if !untitled.isEmpty { out.append(Section(title: nil, items: untitled)) }
    out.sort { (a, b) in
      switch (a.title, b.title) {
      case (let l?, let r?): return l < r
      case (nil, _?): return false
      case (_?, nil): return true
      default: return false
      }
    }
    return out
  }
}

// MARK: - 0.4.0 Core Types

public struct SystemInstructionsRefs: Codable, Sendable {
  public var compactPath: String?
  public var fullPath: String?
  public var lastUpdated: String?
  public init(compactPath: String? = nil, fullPath: String? = nil, lastUpdated: String? = nil) {
    self.compactPath = compactPath
    self.fullPath = fullPath
    self.lastUpdated = lastUpdated
  }
}

public struct PersonaRefs: Codable, Sendable {
  public var profilePath: String?
  public var reveriesPath: String?

  public init(profilePath: String? = nil, reveriesPath: String? = nil) {
    self.profilePath = profilePath
    self.reveriesPath = reveriesPath
  }
}

public struct CLISpecExport: Codable, Sendable {
  public var export: Bool
  public var path: String?
  public init(export: Bool = false, path: String? = nil) {
    self.export = export
    self.path = path
  }
}

// MARK: - Contribution Mix (Agent defaults)
public struct ContributionMix: Codable, Sendable {
  public var primary: [Contribution]
  public var secondary: [Contribution]?
  public init(primary: [Contribution], secondary: [Contribution]? = nil) {
    self.primary = primary
    self.secondary = secondary
  }
}

// MARK: - Focus Domains

public struct FocusDomain: Codable, Sendable {
  public var label: String
  public var identifier: String
  public var weight: Double?
  public init(label: String, identifier: String, weight: Double? = nil) {
    self.label = label
    self.identifier = identifier
    self.weight = weight
  }
}

// MARK: - ContributionMix helpers (validation + normalization)

extension ContributionMix {
  /// Return the set of contribution type identifiers that are not present in the allowed roles set.
  /// - Parameter allowed: set of valid S‑Types role identifiers (kebab‑case)
  /// - Returns: unique list of unknown types across primary and secondary
  public func unknownRoles(allowed: Set<String>) -> [String] {
    var out: Set<String> = []
    for c in primary where !allowed.contains(c.type) { out.insert(c.type) }
    if let s = secondary {
      for c in s where !allowed.contains(c.type) { out.insert(c.type) }
    }
    return Array(out).sorted()
  }

  /// Return the set of contribution type identifiers that have non‑positive weights.
  /// - Parameter minimum: lower bound (exclusive) for valid weights; default > 0
  public func invalidWeights(minimum: Double = 0.0) -> [String] {
    var out: Set<String> = []
    for c in primary where c.weight <= minimum { out.insert(c.type) }
    if let s = secondary {
      for c in s where c.weight <= minimum { out.insert(c.type) }
    }
    return Array(out).sorted()
  }

  /// Normalized shares per type for the primary list (last‑wins per type).
  /// - Returns: map type -> share (sum of values equals 1.0 when any weight > 0; empty when all zero)
  public func normalizedPrimary() -> [String: Double] {
    normalize(list: primary)
  }

  /// Normalized shares per type for the secondary list (last‑wins per type).
  public func normalizedSecondary() -> [String: Double]? {
    guard let s = secondary else { return nil }
    return normalize(list: s)
  }

  /// Normalizes a list of contributions by last‑wins coalescing then dividing by the sum of weights.
  private func normalize(list: [Contribution]) -> [String: Double] {
    var map: [String: Double] = [:]
    for c in list { map[c.type] = c.weight }
    let denom = map.values.reduce(0.0, +)
    guard denom > 0 else { return [:] }
    var out: [String: Double] = [:]
    for (k, v) in map { out[k] = v / denom }
    return out
  }
}
