import CLIACoreModels
import Foundation

public enum Merger {
  public static func mergeAgent(slug: String, under root: URL, options: MergeOptions = .init())
    -> MergedAgentView
  {
    let docs = loadDocs(AgentDoc.self, slug: slug, under: root, suffix: ".agent.triad.json")
    var view = reduceAgentDocs(docs)
    // Preserve requested identity: when reduction cannot determine a specific slug
    // or only root profile contributed, prefer the input slug.
    if view.slug.isEmpty || view.slug == "unknown" || view.slug == "agent-profile" {
      view.slug = slug
    }
    // Derive origin (read-only)
    view.origin = OriginDeriver.derive(for: slug, under: root)
    return view
  }
  public static func mergeAgenda(slug: String, under root: URL, options: MergeOptions = .init())
    -> MergedAgendaView
  {
    let docs = loadDocs(AgendaDoc.self, slug: slug, under: root, suffix: ".agenda.triad.json")
    var view = reduceAgendaDocs(docs)
    if view.slug.isEmpty || view.slug == "unknown" || view.slug == "agent-profile" {
      view.slug = slug
    }
    view.origin = OriginDeriver.derive(for: slug, under: root)
    return view
  }
  public static func mergeAgency(slug: String, under root: URL, options: MergeOptions = .init())
    -> MergedAgencyView
  {
    let docs = loadDocs(AgencyDoc.self, slug: slug, under: root, suffix: ".agency.triad.json")
    var view = reduceAgencyDocs(docs)
    if view.slug.isEmpty || view.slug == "unknown" || view.slug == "agent-profile" {
      view.slug = slug
    }
    view.origin = OriginDeriver.derive(for: slug, under: root)
    return view
  }

  private static func loadDocs<T: Decodable>(
    _: T.Type, slug: String, under root: URL, suffix: String
  ) -> [T] {
    var out: [T] = []
    let dec = JSONDecoder()
    let fm = FileManager.default

    // Cycle-safe decode with inheritance support
    var visitedPaths = Set<String>()

    func inheritsList(from raw: Any) -> [String] {
      guard let dict = raw as? [String: Any] else { return [] }
      if let inh = dict["inherits"] as? [String] { return inh }
      return []
    }

    func decodeWithInheritance(at url: URL) {
      let path = url.standardizedFileURL.path
      guard visitedPaths.insert(path).inserted else { return }
      guard let data = try? Data(contentsOf: url) else { return }
      // Parse raw JSON to discover inheritance, then append inherited docs first (lower precedence)
      if let raw = try? JSONSerialization.jsonObject(with: data) {
        let inh = inheritsList(from: raw)
        for rel in inh {
          let child =
            rel.hasPrefix("/") ? URL(fileURLWithPath: rel) : root.appendingPathComponent(rel)
          if fm.fileExists(atPath: child.path) {
            decodeWithInheritance(at: child)
          }
        }
        if let decoded = try? dec.decode(T.self, from: data) {
          out.append(decoded)
        }
      }
    }

    // Resolve lineage directories (ancestors + preferred local path)
    let items = LineageResolver.findAgentDirs(for: slug, under: root)
    let preferred = root.appendingPathComponent(".clia/agents/\(slug)")
    var dirs = items.map { $0.dir }
    if !dirs.contains(where: { $0.path == preferred.path }) { dirs.append(preferred) }
    var seenDirs = Set<String>()
    for dir in dirs where seenDirs.insert(dir.path).inserted {
      if let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
        let u = urls.first(where: { $0.lastPathComponent.hasSuffix(suffix) })
      {
        decodeWithInheritance(at: u)
      }
    }
    return out
  }

  private static func reduceAgentDocs(_ docs: [AgentDoc]) -> MergedAgentView {
    let now = ISO8601DateFormatter().string(from: Date())
    func last<T>(_ get: (AgentDoc) -> T, empty: (T) -> Bool) -> T? {
      for d in docs.reversed() {
        let v = get(d)
        if !empty(v) { return v }
      }
      return nil
    }
    let slug = last({ $0.slug }, empty: { $0.isEmpty }) ?? "unknown"
    let title = last({ $0.title }, empty: { $0.isEmpty }) ?? slug
    let updated = last({ $0.updated }, empty: { $0.isEmpty }) ?? now
    let schema =
      last({ $0.schemaVersion }, empty: { $0.isEmpty })
      ?? TriadSchemaVersion.current
    let status = last({ $0.status }, empty: { $0?.isEmpty ?? true }) ?? nil
    let role = last({ $0.role ?? "" }, empty: { $0.isEmpty }) ?? slug
    let mentors = unionStrings(docs.map { $0.mentors })
    let tags = unionStrings(docs.map { $0.tags })
    let links = unionLinks(docs.map { $0.links })
    let purpose = last({ $0.purpose }, empty: { $0?.isEmpty ?? true }) ?? nil
    let responsibilities = unionStrings(docs.map { $0.responsibilities })
    let guardrails = unionStrings(docs.map { $0.guardrails })
    let checklists = unionStrings(docs.map { flattenChecklist($0.checklists) })
    let sections = unionStrings(docs.map { flattenSections($0.sections) })
    let notes = last({ $0.notes }, empty: { $0.isEmpty }) ?? []
    let ext = last({ $0.extensions }, empty: { $0?.isEmpty ?? true }) ?? nil
    let emojiTags = unionStrings(docs.map { $0.emojiTags })
    let resolvedContributionMix: ContributionMix? = {
      // Inherit-and-union semantics: accumulate contributions across all docs
      // (inherited first, then local), last-wins per type for weights.
      var primaryByType: [String: Contribution] = [:]
      var secondaryByType: [String: Contribution] = [:]
      for d in docs {
        if let mix = d.contributionMix {
          for c in mix.primary { primaryByType[c.type] = c }
          if let s = mix.secondary {
            for c in s { secondaryByType[c.type] = c }
          }
        }
      }
      let primary = Array(primaryByType.values)
      let secondary = Array(secondaryByType.values)
      if primary.isEmpty && secondary.isEmpty { return nil }
      return ContributionMix(primary: primary, secondary: secondary.isEmpty ? nil : secondary)
    }()
    // Resolve persona/system-instructions with inheritance semantics.
    // Partial overrides allowed: choose last non-empty per-field across docs.
    func lastString(_ selector: (AgentDoc) -> String?) -> String? {
      for d in docs.reversed() {
        if let s = selector(d), !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          return s
        }
      }
      return nil
    }
    let avatarPath = lastString { $0.avatarPath }
    let figletFontName = lastString { $0.figletFontName }
    let resolvedPersona: PersonaRefs? = {
      if let p = lastString({ $0.persona?.profilePath }) { return PersonaRefs(profilePath: p) }
      return nil
    }()
    let resolvedSystem: SystemInstructionsRefs? = {
      let compact = lastString { $0.systemInstructions?.compactPath }
      let full = lastString { $0.systemInstructions?.fullPath }
      let updated = lastString { $0.systemInstructions?.lastUpdated }
      if compact != nil || full != nil || updated != nil {
        return SystemInstructionsRefs(compactPath: compact, fullPath: full, lastUpdated: updated)
      }
      return nil
    }()
    let resolvedCLISpec: CLISpecExport? = {
      // Prefer last with non-empty path or export=true
      for d in docs.reversed() {
        if let s = d.cliSpec {
          if s.export || !(s.path ?? "").isEmpty { return s }
        }
      }
      return nil
    }()
    return .init(
      schemaVersion: schema, slug: slug, title: title, updated: updated, status: status, role: role,
      mentors: mentors, tags: tags, links: links, purpose: purpose,
      responsibilities: responsibilities, guardrails: guardrails, checklists: checklists,
      sections: sections, notes: notes, avatarPath: avatarPath,
      figletFontName: figletFontName, extensions: ext,
      emojiTags: emojiTags, contributionMix: resolvedContributionMix,
      persona: resolvedPersona, systemInstructions: resolvedSystem,
      cliSpec: resolvedCLISpec, contextChain: nil)
  }

  private static func reduceAgendaDocs(_ docs: [AgendaDoc]) -> MergedAgendaView {
    let now = ISO8601DateFormatter().string(from: Date())
    func last<T>(_ get: (AgendaDoc) -> T, empty: (T) -> Bool) -> T? {
      for d in docs.reversed() {
        let v = get(d)
        if !empty(v) { return v }
      }
      return nil
    }
    let slug = last({ $0.slug }, empty: { $0.isEmpty }) ?? "unknown"
    let title = last({ $0.title }, empty: { $0.isEmpty }) ?? slug
    let updated = last({ $0.updated }, empty: { $0.isEmpty }) ?? now
    let schema =
      last({ $0.schemaVersion }, empty: { $0.isEmpty })
      ?? TriadSchemaVersion.current
    let subtitle = last({ $0.subtitle }, empty: { $0?.isEmpty ?? true }) ?? nil
    let status = last({ $0.status }, empty: { $0?.isEmpty ?? true }) ?? nil
    let agentRef = last({ $0.agent }, empty: { _ in false }) ?? .init(role: slug)
    let mentors = unionStrings(docs.map { $0.mentors })
    let tags = unionStrings(docs.map { $0.tags })
    let links = unionLinks(docs.map { $0.links })
    let northStar = last({ $0.northStar }, empty: { $0?.isEmpty ?? true }) ?? nil
    let principles = unionStrings(docs.map { $0.principles })
    let themes = unionStrings(docs.map { $0.themes })
    let horizons = unionStrings(docs.map { flattenHorizons($0.horizons) })
    let initiatives = unionStrings(docs.map { $0.initiatives })
    let milestones = unionStrings(docs.map { flattenMilestones($0.milestones) })
    let backlog = unionStrings(docs.map { flattenBacklog($0.backlog) })
    let metrics = last({ $0.metrics }, empty: { $0?.isEmpty ?? true }) ?? nil
    let cadence = last({ $0.cadence }, empty: { $0?.isEmpty ?? true }) ?? nil
    let dependencies = unionStrings(docs.map { $0.dependencies })
    let risks = unionStrings(docs.map { $0.risks })
    let crossLinks = last({ $0.crossLinks }, empty: { $0?.isEmpty ?? true }) ?? nil
    let sections = unionStrings(docs.map { flattenSections($0.sections) })
    let notes: [Note] = {
      for d in docs.reversed() {
        let v = d.notes
        if !v.isEmpty { return v }
      }
      return []
    }()
    let ext = last({ $0.extensions }, empty: { $0?.isEmpty ?? true }) ?? nil
    return .init(
      schemaVersion: schema, slug: slug, title: title, subtitle: subtitle, updated: updated,
      status: status, agent: agentRef, mentors: mentors, tags: tags, links: links,
      northStar: northStar, principles: principles, themes: themes, horizons: horizons,
      initiatives: initiatives, milestones: milestones, backlog: backlog, metrics: metrics,
      cadence: cadence, dependencies: dependencies, risks: risks, crossLinks: crossLinks,
      sections: sections, notes: notes, extensions: ext, contextChain: nil)
  }

  private static func flattenHorizons(_ horizons: [Horizon]) -> [String] {
    var out: [String] = []
    for h in horizons {
      let title = h.title
      if h.items.isEmpty {
        if !title.isEmpty { out.append(title) }
      } else {
        for item in h.items { out.append(title.isEmpty ? item : "\(title): \(item)") }
      }
    }
    return out
  }

  private static func flattenMilestones(_ milestones: [Milestone]) -> [String] {
    milestones.map { m in
      if let due = m.due, !due.isEmpty { return "\(m.title) (due: \(due))" }
      return m.title
    }
  }

  private static func flattenBacklog(_ backlog: [BacklogItem]) -> [String] {
    backlog.map { $0.title }
  }

  private static func reduceAgencyDocs(_ docs: [AgencyDoc]) -> MergedAgencyView {
    let now = ISO8601DateFormatter().string(from: Date())
    func last<T>(_ get: (AgencyDoc) -> T, empty: (T) -> Bool) -> T? {
      for d in docs.reversed() {
        let v = get(d)
        if !empty(v) { return v }
      }
      return nil
    }
    let slug = last({ $0.slug }, empty: { $0.isEmpty }) ?? "unknown"
    let title = last({ $0.title }, empty: { $0.isEmpty }) ?? slug
    let updated = last({ $0.updated }, empty: { $0.isEmpty }) ?? now
    let schema =
      last({ $0.schemaVersion }, empty: { $0.isEmpty })
      ?? TriadSchemaVersion.current
    let status = last({ $0.status }, empty: { $0?.isEmpty ?? true }) ?? nil
    let mentors = unionStrings(docs.map { $0.mentors })
    let tags = unionStrings(docs.map { $0.tags })
    let links = unionLinks(docs.map { $0.links })
    let entries = unionEntries(docs.map { $0.entries })
    let sections = unionStrings(docs.map { flattenSections($0.sections) })
    let notes = last({ $0.notes }, empty: { $0.isEmpty }) ?? []
    let ext = last({ $0.extensions }, empty: { $0?.isEmpty ?? true }) ?? nil
    return .init(
      schemaVersion: schema,
      slug: slug,
      title: title,
      updated: updated,
      status: status,
      mentors: mentors,
      tags: tags,
      links: links,
      entries: entries,
      sections: sections,
      notes: notes,
      extensions: ext,
      contextChain: nil)
  }

  private static func unionStrings(_ list: [[String]]) -> [String] {
    var seen = Set<String>()
    var out: [String] = []
    for arr in list {
      for s in arr where !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        if seen.insert(s).inserted { out.append(s) }
      }
    }
    return out
  }
  private static func unionLinks(_ list: [[LinkRef]]) -> [LinkRef] {
    var seen = Set<String>()
    var out: [LinkRef] = []
    for arr in list {
      for l in arr {
        let key = (l.title ?? "") + "|" + (l.url ?? "")
        if seen.insert(key).inserted { out.append(l) }
      }
    }
    return out
  }

  private static func unionEntries(_ list: [[AgencyEntry]]) -> [AgencyEntry] {
    var seen = Set<String>()
    var out: [AgencyEntry] = []
    func key(_ e: AgencyEntry) -> String { "\(e.timestamp)|\(e.title ?? "")" }
    for arr in list {
      for e in arr {
        let k = key(e)
        if seen.insert(k).inserted { out.append(e) }
      }
    }
    return out
  }

  // MARK: - Flatten helpers
  private static func flattenSections(_ v: [Section]) -> [String] {
    var out: [String] = []
    for s in v {
      if let t = s.title, s.items.isEmpty { out.append(t) }
      if !s.items.isEmpty {
        let prefix = (s.title ?? "")
        for item in s.items {
          out.append(prefix.isEmpty ? item : "\(prefix): \(item)")
        }
      }
    }
    return out
  }
  private static func flattenChecklist(_ v: [Checklist]) -> [String] {
    var out: [String] = []
    for c in v {
      if let t = c.title, !t.isEmpty { out.append(t) }
      for item in c.items { out.append(item.text) }
    }
    return out
  }
}
