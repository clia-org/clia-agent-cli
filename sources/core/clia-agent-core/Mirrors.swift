import Foundation
import SwiftMDFormatter

public enum MirrorRenderer {
  public static func mirrorAgents(
    at agentsRoot: URL,
    slugs: Set<String>? = nil,
    dryRun: Bool = false
  ) throws -> [URL] {
    let fm = FileManager.default
    guard fm.fileExists(atPath: agentsRoot.path) else {
      throw NSError(
        domain: "MirrorRenderer", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Agents directory not found: \(agentsRoot.path)"])
    }
    let triadSuffixes = ["agent.json", "agenda.json", "agency.json"]
    var agentDirs = try fm.contentsOfDirectory(
      at: agentsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
    ).filter { url in
      var isDir: ObjCBool = false
      return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
    if let slugs, !slugs.isEmpty {
      agentDirs = agentDirs.filter { slugs.contains($0.lastPathComponent) }
    }
    var written: [URL] = []
    for dir in agentDirs {
      let files = try fm.contentsOfDirectory(
        at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      for file in files
      where triadSuffixes.contains(where: { file.lastPathComponent.hasSuffix($0) }) {
        do {
          let data = try Data(contentsOf: file)
          guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            continue
          }
          let slug = (json["slug"] as? String) ?? dir.lastPathComponent
          let title = (json["title"] as? String) ?? slug
          let updated = json["updated"] as? String
          let handle = json["handle"] as? String
          let type: String =
            file.lastPathComponent.hasSuffix("agent.json")
            ? "agent" : (file.lastPathComponent.hasSuffix("agenda.json") ? "agenda" : "agency")
          // Output filename: write legacy-consistent agent.md for agent profile mirrors
          let mdName = type == "agent" ? "\(slug).agent.md" : "\(slug).\(type).md"
          let generatedDir = dir.appendingPathComponent(".generated")
          if !dryRun {
            try? fm.createDirectory(at: generatedDir, withIntermediateDirectories: true)
          }
          let mdURL = generatedDir.appendingPathComponent(mdName)
          var md: String
          if type == "agenda" {
            // Use the richer agenda renderer shared with the standalone command
            let rendered = try agendaMarkdown(from: file)
            md = rendered.markdown
          } else if type == "agency" {
            let entries = extractEntries(json["entries"])
            let notesBlocks = extractBlocks(json["notes"])
            // Resolve agentsRoot for role lookups (participants rendering)
            let agentsRoot = agentsRoot
            md = renderAgencyMirror(
              title: title,
              handle: handle,
              updated: updated,
              entries: entries,
              notes: notesBlocks,
              agentsRoot: agentsRoot)
          } else if type == "agent" {
            md = renderAgentProfile(
              json: json,
              title: title,
              handle: handle,
              updated: updated,
              workingDir: dir)
          } else {
            let notesBlocks = extractBlocks(json["notes"])
            md = renderMirror(
              title: title, handle: handle, updated: updated, type: type, notes: notesBlocks)
          }
          if dryRun {
            written.append(mdURL)
          } else {
            // Best-effort removal of previous agent-profile.md to avoid stale mirrors after rename
            if type == "agent" {
              let old = generatedDir.appendingPathComponent("\(slug).agent-profile.md")
              if fm.fileExists(atPath: old.path) { try? fm.removeItem(at: old) }
            }
            try md.write(to: mdURL, atomically: true, encoding: .utf8)
            let formatResult = SwiftMDFormatter().format(
              paths: [mdURL.path],
              check: false,
              writeTo: nil
            )
            if formatResult.errorCount > 0 {
              fputs("mirrors: markdown format failed for \(mdURL.path)\n", stderr)
            }
            written.append(mdURL)
          }
        } catch {
          fputs("mirrors: failed for \(file.path): \(error)\n", stderr)
        }
      }
    }
    return written
  }

  public static func agendaMarkdown(from url: URL) throws -> (slug: String, markdown: String) {
    let data = try Data(contentsOf: url)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw NSError(
        domain: "MirrorRenderer", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON at \(url.path)"])
    }
    let slug = (json["slug"] as? String) ?? url.deletingPathExtension().lastPathComponent
    let title = (json["title"] as? String) ?? slug
    let notesBlocks = extractBlocks(json["notes"])
    var lines: [String] = []
    lines.append("# \(title) — Agenda\n")
    lines.append("| Cadence | Checkpoint | Notes |\n| ------- | ---------- | ----- |")
    lines.append("| Daily | | |")
    lines.append("| Weekly | | |")
    lines.append("| Ad-hoc | | |\n")
    lines.append("## Notes")
    for block in notesBlocks {
      if block.kind.lowercased() == "list" {
        for t in block.text { lines.append("- \(t)") }
      } else {
        for t in block.text { lines.append(t) }
      }
    }
    lines.append("")
    return (slug, lines.joined(separator: "\n"))
  }

  public static func agentMarkdown(from url: URL) throws -> (slug: String, markdown: String) {
    let data = try Data(contentsOf: url)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw NSError(
        domain: "MirrorRenderer", code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON at \(url.path)"])
    }
    let slug = (json["slug"] as? String) ?? url.deletingPathExtension().lastPathComponent
    let title = (json["title"] as? String) ?? slug
    let handle = json["handle"] as? String
    let updated = json["updated"] as? String
    let workingDir = url.deletingLastPathComponent()
    let markdown = renderAgentProfile(
      json: json,
      title: title,
      handle: handle,
      updated: updated,
      workingDir: workingDir
    )
    return (slug, markdown)
  }

  public static func agencyMarkdown(from url: URL) throws -> (slug: String, markdown: String) {
    let data = try Data(contentsOf: url)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw NSError(
        domain: "MirrorRenderer", code: 4,
        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON at \(url.path)"])
    }
    let slug = (json["slug"] as? String) ?? url.deletingPathExtension().lastPathComponent
    let title = (json["title"] as? String) ?? slug
    let updated = json["updated"] as? String
    let handle = json["handle"] as? String
    let entries = extractEntries(json["entries"])
    let notesBlocks = extractBlocks(json["notes"])
    let agentsRoot = url.deletingLastPathComponent().deletingLastPathComponent()
    let markdown = renderAgencyMirror(
      title: title,
      handle: handle,
      updated: updated,
      entries: entries,
      notes: notesBlocks,
      agentsRoot: agentsRoot
    )
    return (slug, markdown)
  }

  private struct Block {
    let kind: String
    let text: [String]
  }
  private static func extractBlocks(_ value: Any?) -> [Block] {
    guard let dict = value as? [String: Any], let arr = dict["blocks"] as? [Any] else { return [] }
    return arr.compactMap { any in
      guard let d = any as? [String: Any] else { return nil }
      let kind = (d["kind"] as? String) ?? "paragraph"
      let text = (d["text"] as? [String]) ?? []
      return Block(kind: kind, text: text)
    }
  }

  private struct AgencyEntryLite {
    let timestamp: String
    let kind: String?
    let title: String?
    let summary: String?
    let details: [String]
    let participants: [String]
    let tags: [String]
    let links: [(title: String?, url: String?)]
    // New grouped contributions; when present, participants are derived from groups
    let contributionGroups: [ContributionGroupLite]?
  }
  private struct ContributionGroupLite {
    let by: String
    let items: [ContributionItemLite]
  }
  private struct ContributionItemLite {
    let type: String
    let weight: Double
    let evidence: String?
  }
  private static func extractEntries(_ value: Any?) -> [AgencyEntryLite] {
    guard let arr = value as? [Any] else { return [] }
    var out: [AgencyEntryLite] = []
    for v in arr {
      guard let d = v as? [String: Any], let ts = d["timestamp"] as? String else { continue }
      let kind = d["kind"] as? String
      let title = d["title"] as? String
      let summary = d["summary"] as? String
      let details = (d["details"] as? [String]) ?? []
      let participants = (d["participants"] as? [String]) ?? []
      let tags = (d["tags"] as? [String]) ?? []
      var links: [(String?, String?)] = []
      if let larr = d["links"] as? [Any] {
        for any in larr {
          if let ld = any as? [String: Any] {
            links.append((ld["title"] as? String, ld["url"] as? String))
          }
        }
      }
      // Parse grouped contributions if present under "contributions"
      var contribGroups: [ContributionGroupLite]? = nil
      if let carr = d["contributions"] as? [Any], !carr.isEmpty {
        var groups: [ContributionGroupLite] = []
        var parsedGrouped = false
        // Try grouped shape first: [{ by, types: [{type,weight?,evidence?}] }]
        for any in carr {
          if let gd = any as? [String: Any], let by = gd["by"] as? String,
            let typesAny = gd["types"] as? [Any]
          {
            var items: [ContributionItemLite] = []
            for t in typesAny {
              if let td = t as? [String: Any], let ty = td["type"] as? String {
                let w = (td["weight"] as? Double) ?? (td["weight"] as? Int).map(Double.init) ?? 1.0
                let ev = td["evidence"] as? String
                items.append(.init(type: ty, weight: w, evidence: ev))
              }
            }
            groups.append(.init(by: by, items: items))
            parsedGrouped = true
          }
        }
        if parsedGrouped { contribGroups = groups }
      }
      out.append(
        .init(
          timestamp: ts, kind: kind, title: title, summary: summary, details: details,
          participants: participants, tags: tags, links: links, contributionGroups: contribGroups))
    }
    // Newest-first by timestamp string (ISO8601 sorts lexicographically)
    return out.sorted { $0.timestamp > $1.timestamp }
  }

  private static func renderMirror(
    title: String, handle: String?, updated: String?, type: String, notes: [Block]
  ) -> String {
    var lines: [String] = []
    let heading: String = {
      switch type {
      case "agent": return "# \(title)"
      case "agenda": return "# \(title) — Agenda"
      default: return "# \(title) — Agency"
      }
    }()
    lines.append(heading)
    lines.append("")
    if let handle, !handle.isEmpty { lines.append("_Handle: \(handle)_") }
    if let updated { lines.append("_Updated: \(updated)_") }
    lines.append("")
    if !notes.isEmpty {
      lines.append("## Notes")
      for block in notes {
        if block.kind.lowercased() == "list" {
          for t in block.text { lines.append("- \(t)") }
        } else {
          for t in block.text { lines.append(t) }
        }
      }
    }
    lines.append("")
    return lines.joined(separator: "\n")
  }

  private static func renderAgencyMirror(
    title: String,
    handle: String?,
    updated: String?,
    entries: [AgencyEntryLite],
    notes: [Block],
    agentsRoot: URL
  ) -> String {
    var lines: [String] = []
    lines.append("# \(title) — Agency")
    lines.append("")
    if let handle, !handle.isEmpty { lines.append("_Handle: \(handle)_") }
    if let updated { lines.append("_Updated: \(updated)_") }
    lines.append("")

    if !entries.isEmpty {
      lines.append("## Agency log")
      for e in entries {
        let kind = e.kind?.isEmpty == false ? e.kind! : "journal"
        var header = "### \(e.timestamp) — \(kind)"
        if let t = e.title, !t.isEmpty { header += " — \(t)" }
        lines.append(header)
        if let s = e.summary, !s.isEmpty { lines.append("\n- Summary: \(s)") }
        for d in e.details { lines.append("- \(d)") }
        // Participants: prefer derived from grouped contributions
        let partSlugs: [String] = {
          if let groups = e.contributionGroups { return groups.map { $0.by } }
          return e.participants
        }()
        if !partSlugs.isEmpty {
          let pretty = partSlugs.map { slug -> String in
            let role = resolveDisplayRole(slug: slug, under: agentsRoot) ?? slug
            return "\(role) (^\(slug))"
          }
          lines.append("- Participants: \(pretty.joined(separator: ", "))")
        }
        // Contributions (grouped)
        if let groups = e.contributionGroups, !groups.isEmpty {
          lines.append("- Contributions:")
          for g in groups {
            let role = resolveDisplayRole(slug: g.by, under: agentsRoot) ?? g.by
            var parts: [String] = []
            for item in g.items {
              let w = trimDouble(item.weight)
              if let ev = item.evidence, !ev.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              {
                parts.append("\(item.type)=\(w) — \(ev)")
              } else {
                parts.append("\(item.type)=\(w)")
              }
            }
            lines.append("  - \(role) (^\(g.by)): \(parts.joined(separator: "; "))")
          }
        }
        if !e.tags.isEmpty { lines.append("- Tags: \(e.tags.joined(separator: ", "))") }
        if !e.links.isEmpty {
          for l in e.links {
            if let url = l.url, !url.isEmpty {
              let title = (l.title?.isEmpty == false) ? l.title! : url
              lines.append("- Link: [\(title)](\(url))")
            }
          }
        }
        lines.append("")
      }
    }

    if !notes.isEmpty {
      lines.append("\n## Notes")
      for block in notes {
        if block.kind.lowercased() == "list" {
          for t in block.text { lines.append("- \(t)") }
        } else {
          for t in block.text { lines.append(t) }
        }
      }
    }
    lines.append("")
    return lines.joined(separator: "\n")
  }

  private static func resolveDisplayRole(slug: String, under agentsRoot: URL) -> String? {
    let fm = FileManager.default
    let dir = agentsRoot.appendingPathComponent(slug)
    guard fm.fileExists(atPath: dir.path) else { return nil }
    if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      if let agentURL = files.first(where: {
        $0.lastPathComponent.hasSuffix(".agent.json") && !$0.lastPathComponent.contains(".agency.")
      }) {
        if let data = try? Data(contentsOf: agentURL),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
          if let role = obj["role"] as? String,
            !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
          {
            return role
          }
        }
      }
    }
    return nil
  }

  // MARK: - Agent profile renderer
  private static func renderAgentProfile(
    json: [String: Any], title: String, handle: String?, updated: String?, workingDir: URL
  ) -> String {
    // Identity
    let slug = (json["slug"] as? String) ?? ""
    let role = (json["role"] as? String) ?? slug
    let status = json["status"] as? String
    let mentors = (json["mentors"] as? [String]) ?? []
    let emojiTags = (json["emojiTags"] as? [String]) ?? []

    // Content
    let purpose = json["purpose"] as? String
    let responsibilities = (json["responsibilities"] as? [String]) ?? []
    let guardrails = (json["guardrails"] as? [String]) ?? []
    let checklists = extractChecklistLines(json["checklists"])  // flattened strings
    let sections = extractSections(json["sections"])  // [(title?, items)]
    let notesBlocks = extractBlocks(json["notes"])  // structured notes
    let links = extractLinks(json["links"])  // [(title?, url?)]
    let contributionMix = extractContributionMix(json["contributionMix"])  // (primary, secondary)
    let focusDomains = extractFocusDomains(json["focusDomains"])  // [Focus]

    // Resolve repo root from workingDir: <repo>/.clia/agents/<slug>
    let repoRoot = workingDir.deletingLastPathComponent()  // .../agents
      .deletingLastPathComponent()  // .../clia
      .deletingLastPathComponent()  // .../.wrkstrm
      .deletingLastPathComponent()  // repo root

    // Persona (optional include of external profile markdown)
    let personaMarkdown: String? = {
      guard let persona = json["persona"] as? [String: Any],
        let profilePath = persona["profilePath"] as? String,
        !profilePath.isEmpty
      else { return nil }
      if let s = try? readText(at: profilePath, repoRoot: repoRoot, workingDir: workingDir) {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : s
      }
      return nil
    }()

    // Persona reveries (micro-behaviors), if present
    let reveriesMarkdown: String? = {
      guard let persona = json["persona"] as? [String: Any],
        let path = persona["reveriesPath"] as? String,
        !path.isEmpty
      else { return nil }
      if let s = try? readText(at: path, repoRoot: repoRoot, workingDir: workingDir) {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : s
      }
      return nil
    }()

    // Agent source document (human-authored), if present
    let agentDocMarkdown: String? = {
      if let sourcePath = json["sourcePath"] as? String, !sourcePath.isEmpty,
        let s = try? readText(at: sourcePath, repoRoot: repoRoot, workingDir: workingDir)
      {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : s
      }
      return nil
    }()

    // System instructions (compact), if present
    let systemInstructionsCompact: String? = {
      guard let si = json["systemInstructions"] as? [String: Any],
        let compactPath = si["compactPath"] as? String,
        !compactPath.isEmpty
      else { return nil }
      if let s = try? readText(at: compactPath, repoRoot: repoRoot, workingDir: workingDir) {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : s
      }
      return nil
    }()

    var lines: [String] = []
    lines.append("# \(title) — Agent Profile")
    lines.append("")
    if let handle, !handle.isEmpty { lines.append("_Handle: \(handle)_") }
    if let status, !status.isEmpty { lines.append("_Status: \(status)_") }
    if let updated { lines.append("_Updated: \(updated)_") }
    lines.append("")

    lines.append("\n## Identity")
    lines.append("- Slug: \(slug)")
    lines.append("- Role: \(role)")
    if !mentors.isEmpty { lines.append("- Mentors: \(mentors.joined(separator: ", "))") }
    if let mix = contributionMix {
      let primaryLines = renderMixLines(mix.primary)
      if !primaryLines.isEmpty {
        lines.append("- Contribution mix (primary):")
        for line in primaryLines { lines.append("  - \(line)") }
      }
      if let secondary = mix.secondary {
        let secondaryLines = renderMixLines(secondary)
        if !secondaryLines.isEmpty {
          lines.append("- Contribution mix (secondary):")
          for line in secondaryLines { lines.append("  - \(line)") }
        }
      }
    }
    if !emojiTags.isEmpty { lines.append("- Emoji tags: \(emojiTags.joined(separator: " "))") }

    if let purpose, !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      lines.append("\n## Purpose\n")
      lines.append(purpose)
    }

    if !responsibilities.isEmpty {
      lines.append("\n## Responsibilities")
      for r in responsibilities { lines.append("- \(r)") }
    }
    if !guardrails.isEmpty {
      lines.append("\n## Guardrails")
      for g in guardrails { lines.append("- \(g)") }
    }
    if let mix = contributionMix, !mix.primary.isEmpty || !(mix.secondary?.isEmpty ?? true) {
      lines.append("\n## Contribution mix")
      if !mix.primary.isEmpty {
        lines.append("\n### Primary")
        for line in renderMixLines(mix.primary) { lines.append("- \(line)") }
      }
      if let sec = mix.secondary, !sec.isEmpty {
        lines.append("\n### Secondary")
        for line in renderMixLines(sec) { lines.append("- \(line)") }
      }
    }
    if let fds = focusDomains, !fds.isEmpty {
      lines.append("\n## Focus domains")
      for line in renderFocusDomainLines(fds) { lines.append("- \(line)") }
    }
    if !checklists.isEmpty {
      lines.append("\n## Checklists")
      for c in checklists { lines.append("- \(c)") }
    }
    if !sections.isEmpty {
      lines.append("\n## Sections")
      for sec in sections {
        if let t = sec.title, !t.isEmpty { lines.append("\n### \(t)") }
        for item in sec.items { lines.append("- \(item)") }
      }
    }
    if !links.isEmpty {
      lines.append("\n## Links")
      for l in links {
        if let url = l.url, !url.isEmpty {
          let title = (l.title?.isEmpty == false) ? l.title! : url
          lines.append("- [\(title)](\(url))")
        }
      }
    }
    // Include agent source and persona content as dedicated sections
    if let agentDocMarkdown, !agentDocMarkdown.isEmpty {
      lines.append("\n## Agent document (source)")
      lines.append(agentDocMarkdown)
    }
    if let personaMarkdown, !personaMarkdown.isEmpty {
      lines.append("\n## Persona")
      lines.append(personaMarkdown)
    }
    if let reveriesMarkdown, !reveriesMarkdown.isEmpty {
      lines.append("\n## Reveries")
      lines.append(reveriesMarkdown)
    }
    if let systemInstructionsCompact, !systemInstructionsCompact.isEmpty {
      lines.append("\n## System instructions (compact)")
      lines.append(systemInstructionsCompact)
    }
    if !notesBlocks.isEmpty {
      lines.append("\n## Notes")
      for block in notesBlocks {
        if block.kind.lowercased() == "list" {
          for t in block.text { lines.append("- \(t)") }
        } else {
          for t in block.text { lines.append(t) }
        }
      }
    }
    lines.append("")
    return lines.joined(separator: "\n")
  }

  private struct SectionLite {
    let title: String?
    let items: [String]
  }
  private static func extractSections(_ value: Any?) -> [SectionLite] {
    guard let arr = value as? [Any] else { return [] }
    var out: [SectionLite] = []
    for any in arr {
      guard let d = any as? [String: Any] else { continue }
      let title = d["title"] as? String
      let items = (d["items"] as? [String]) ?? []
      out.append(.init(title: title, items: items))
    }
    return out
  }
  private static func extractChecklistLines(_ value: Any?) -> [String] {
    // Accept either typed [{title, items:[String]}] or flat [String]
    if let flat = value as? [String] { return flat }
    guard let arr = value as? [Any] else { return [] }
    var out: [String] = []
    for any in arr {
      if let d = any as? [String: Any] {
        if let t = d["title"] as? String, !t.isEmpty { out.append(t) }
        if let items = d["items"] as? [String] { out.append(contentsOf: items) }
      }
    }
    return out
  }
  private static func extractLinks(_ value: Any?) -> [(title: String?, url: String?)] {
    guard let arr = value as? [Any] else { return [] }
    var out: [(String?, String?)] = []
    for any in arr {
      if let d = any as? [String: Any] {
        out.append((d["title"] as? String, d["url"] as? String))
      }
    }
    return out
  }

  private struct MixItem {
    let type: String
    let weight: Double
  }
  private struct Mix {
    let primary: [MixItem]
    let secondary: [MixItem]?
  }
  private static func extractContributionMix(_ value: Any?) -> Mix? {
    guard let dict = value as? [String: Any] else { return nil }
    func parse(_ any: Any?) -> [MixItem] {
      guard let arr = any as? [Any] else { return [] }
      var out: [MixItem] = []
      for v in arr {
        if let d = v as? [String: Any], let t = d["type"] as? String {
          let w = (d["weight"] as? Double) ?? (d["weight"] as? Int).map(Double.init) ?? 0
          out.append(.init(type: t, weight: w))
        }
      }
      return out
    }
    let primary = parse(dict["primary"])
    let secondary = parse(dict["secondary"])
    if primary.isEmpty && secondary.isEmpty { return nil }
    return .init(primary: primary, secondary: secondary.isEmpty ? nil : secondary)
  }

  private static func renderMixLines(_ items: [MixItem]) -> [String] {
    guard !items.isEmpty else { return [] }
    var lastWins: [String: Double] = [:]
    for i in items { lastWins[i.type] = i.weight }
    let denom = lastWins.values.reduce(0.0, +)
    var lines: [String] = []
    // Sort by descending weight, then type
    for (type, weight) in lastWins.sorted(by: {
      $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value
    }) {
      if denom > 0 {
        let pct = (weight / denom) * 100.0
        lines.append("\(type)=\(trimDouble(weight)) (\(trimDouble(pct))%)")
      } else {
        lines.append("\(type)=\(trimDouble(weight))")
      }
    }
    return lines
  }

  private static func trimDouble(_ v: Double) -> String {
    let s = String(format: "%.3f", v)
    if s.hasSuffix(".000") { return String(Int(v)) }
    var out = s
    while out.contains(".") && (out.hasSuffix("0") || out.hasSuffix(".")) {
      out.removeLast()
    }
    return out
  }

  private struct Focus {
    let label: String
    let identifier: String
    let weight: Double?
  }
  private static func extractFocusDomains(_ value: Any?) -> [Focus]? {
    guard let arr = value as? [Any] else { return nil }
    var out: [Focus] = []
    for any in arr {
      if let d = any as? [String: Any],
        let label = d["label"] as? String,
        let identifier = d["identifier"] as? String
      {
        let w = (d["weight"] as? Double) ?? (d["weight"] as? Int).map(Double.init)
        out.append(.init(label: label, identifier: identifier, weight: w))
      }
    }
    return out.isEmpty ? nil : out
  }

  private static func renderFocusDomainLines(_ items: [Focus]) -> [String] {
    guard !items.isEmpty else { return [] }
    // Normalize weights for percentage when provided
    let weights = items.compactMap { $0.weight }
    let denom = weights.reduce(0.0, +)
    // Sort: descending weight when present, else by label
    let sorted = items.sorted { a, b in
      switch (a.weight, b.weight) {
      case (let wa?, let wb?): return wa == wb ? a.label < b.label : wa > wb
      case (_?, nil): return true
      case (nil, _?): return false
      default: return a.label < b.label
      }
    }
    var lines: [String] = []
    for f in sorted {
      var line = "\(f.label) (#\(f.identifier))"
      if let w = f.weight {
        if denom > 0 {
          let pct = (w / denom) * 100.0
          line += " = \(trimDouble(w)) (\(trimDouble(pct))%)"
        } else {
          line += " = \(trimDouble(w))"
        }
      }
      lines.append(line)
    }
    return lines
  }

  private static func readText(at path: String, repoRoot: URL, workingDir: URL) throws -> String {
    // Skip URLs
    if path.contains("://") {
      throw NSError(
        domain: "MirrorRenderer", code: 3,
        userInfo: [NSLocalizedDescriptionKey: "URL not supported in mirrors: \(path)"])
    }
    let url: URL
    if path.hasPrefix("/") {
      url = URL(fileURLWithPath: path)
    } else if path.hasPrefix(".wrkstrm/") || path.hasPrefix("code/") || path.hasPrefix("docs/")
      || path.hasPrefix("ai/") || path.hasPrefix("notes/") || path.hasPrefix("attachments/")
      || path.hasPrefix("assets/")
    {
      url = repoRoot.appendingPathComponent(path)
    } else {
      url = workingDir.appendingPathComponent(path)
    }
    return try String(contentsOf: url, encoding: .utf8)
  }
}
