import ArgumentParser
import CLIAAgentCore
import CLIAAgentCoreCLICommands
import CLIACoreModels
import Foundation
import Stencil
import SwiftFigletKit
import WrkstrmEnvironment
import WrkstrmFoundation
import WrkstrmMain

// MARK: - Wind

struct Wind: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "wind",
    abstract: "Wind rituals: up, check-in, and down.",
    subcommands: [Up.self, CheckIn.self, Down.self],
  )

  struct Up: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "up",
      abstract: "Wind up: print environment, start timer, update today’s note.",
    )

    @Flag(name: .customLong("kawara-style"), inversion: .prefixedNo, help: "On Kawara wake text.")
    var kawaraStyle: Bool = true

    @Option(name: .customLong("news"), help: "One-line news summary to record today.")
    var news: String?

    @Option(
      name: .customLong("did"), parsing: .upToNextOption,
      help: "Activities already done (repeatable).",
    )
    var did: [String] = []

    @Flag(name: .customLong("no-note"), help: "Do not write to notes; print only.")
    var noNote: Bool = false

    @Flag(
      name: .customLong("no-timer"),
      help: "Suppress timer migration reminder."
    )
    var noTimer: Bool = false

    @Flag(
      name: .customLong("show-environment"),
      help: "Print environment overview (directives)")
    var showEnvironment: Bool = false
    enum DirectivesFormat: String, ExpressibleByArgument, CaseIterable { case json, text, md }
    @Option(
      name: .customLong("env-format"),
      help:
        "Environment overview format: \(DirectivesFormat.allCases.map { $0.rawValue }.joined(separator: ", "))"
    )
    var envFormat: DirectivesFormat = .text
    @Option(
      name: .customLong("env-slug"), help: "Agent slug for environment overview (default: codex)")
    var envSlug: String = "codex"

    mutating func run() async throws {
      try performMorningRitual(
        kawaraStyle: kawaraStyle,
        news: news,
        did: did,
        skipNote: noNote,
        suppressTimerReminder: noTimer,
        showEnvironment: showEnvironment,
        environmentSlug: envSlug,
        environmentFormat: envFormat.rawValue
      )
    }
  }

  struct CheckIn: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "check-in",
      abstract: "Wind check-in: print current heartbeat summary and optional note.",
    )

    @Option(
      name: .customLong("note"), parsing: .upToNextOption,
      help: "Optional note to include in the printed summary.",
    )
    var note: [String] = []

    @Flag(
      name: .customLong("append-agency"),
      help: "Append a concise check-in entry to agency triad (JSON).")
    var appendAgency: Bool = false
    @Option(name: .customLong("slug"), help: "Agent slug to write to (default: auto)") var slug:
      String?

    mutating func run() async throws {
      try performCheckInRitual(note: note, appendAgency: appendAgency, slug: slug)
    }
  }

  struct Down: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "down",
      abstract: "Wind down: append to agency triad (JSON) and update tomorrow’s On deck.",
    )

    @Option(
      name: .customLong("message"), parsing: .upToNextOption,
      help: "Winddown takeaway/inspirational note (logged to agency triad)",
    )
    var message: [String] = []

    @Option(
      name: .customLong("on-deck"), parsing: .upToNextOption,
      help: "Item for tomorrow's 'On deck' section (repeatable)",
    )
    var onDeck: [String] = []

    @Flag(
      name: .customLong("append-journal"),
      help: "Also append a JSON journal entry for the active agent")
    var appendJournal: Bool = false

    @Option(
      name: .customLong("dirs-touched"), parsing: .upToNextOption,
      help: "Directories touched (repeatable); stored as x-dirsTouched in journal"
    )
    var dirsTouched: [String] = []
    @Option(name: .customLong("slug"), help: "Agent slug to write to (default: auto)") var slug:
      String?

    mutating func run() async throws {
      try performWinddownRitual(
        message: message, onDeck: onDeck, appendJournal: appendJournal, dirsTouched: dirsTouched,
        slug: slug)
    }
  }
}

// MARK: - Shared helpers

private let defaultHeartbeatPath = ".clia/tmp/task-heartbeat.json"

private func performMorningRitual(
  kawaraStyle: Bool,
  news: String?,
  did: [String],
  skipNote: Bool,
  suppressTimerReminder: Bool,
  showEnvironment: Bool,
  environmentSlug: String,
  environmentFormat: String
) throws {
  let snapshot = EnvironmentProbe.snapshot()
  print(snapshot.renderPlain())

  // Surface active incident banner if present
  if let banner = loadActiveIncidentBanner() {
    print("\n=== INCIDENT ACTIVE — \(banner.severity.string) — \(banner.title) ===")
    if let summary = banner.summary { print("summary: \(summary)") }
    if let paths = banner.affectedPaths, !paths.isEmpty {
      print("affected:")
      for p in paths { print("- \(p)") }
    }
    if let blocks = banner.doNotModify, !blocks.isEmpty {
      print("do-not-modify:")
      for p in blocks { print("- \(p)") }
    }
    print("owner: \(banner.owner)  id: \(banner.id)  started: \(banner.started)\n")
  }

  if showEnvironment {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    if let repoRoot = findRepoRoot(startingAt: cwd) {
      do {
        let rendered = try DirectivesProfiler.render(
          slug: environmentSlug,
          root: repoRoot,
          format: environmentFormat,
          rootChain: true
        )
        print(
          "\n--- environment overview (directives) [\(environmentSlug)] ---\n" + rendered
            + "\n--- end environment overview ---\n")
      } catch {
        fputs("[warn] failed to render environment overview: \(error)\n", stderr)
      }
    } else {
      fputs("[warn] unable to locate repo root; skipping environment overview\n", stderr)
    }
  }

  let fm = FileManager.default
  let heartbeatExists = fm.fileExists(atPath: defaultHeartbeatPath)
  if !suppressTimerReminder && !heartbeatExists {
    print("No heartbeat found at \(defaultHeartbeatPath); timestamps will use 'unknown' until a timer writes it.")
  }

  let startedAtISO = HeartbeatProbe.startedAtISO8601(at: defaultHeartbeatPath)
  if !skipNote {
    try updateTodayNote(
      using: startedAtISO,
      kawaraStyle: kawaraStyle,
      did: did,
      news: news
    )
  }
  print(
    "\nHint: run 'clia core show-environment --format text' for a full workspace overview."
  )
}

// Resolve agency triad path for a slug by inspecting the agent directory.
private func agencyTriadPath(for slug: String, agentsRoot: URL) -> URL {
  let dir = agentsRoot.appendingPathComponent(slug)
  let fm = FileManager.default
  if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
    if let match = contents.first(where: { $0.lastPathComponent.hasSuffix(".agency.json") }) {
      return match
    }
  }
  let dirTag =
    agentsRoot.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
  // New naming only.
  return dir.appendingPathComponent("\(slug)@\(dirTag).agency.json")
}

private func performCheckInRitual(note: [String], appendAgency: Bool, slug: String?) throws {
  let fm = FileManager.default

  if fm.fileExists(atPath: defaultHeartbeatPath) {
    let summary = try makeStatusSummary(from: defaultHeartbeatPath)
    print(summary)
  } else {
    print("[warn] heartbeat missing at \(defaultHeartbeatPath); status fields may be unknown.")
  }
  if let banner = loadActiveIncidentBanner() {
    print("\n=== INCIDENT ACTIVE — \(banner.severity.string) — \(banner.title) ===")
    if let summary = banner.summary { print("summary: \(summary)") }
    if let paths = banner.affectedPaths, !paths.isEmpty {
      print("affected: \(paths.joined(separator: ", "))")
    }
    if let blocks = banner.doNotModify, !blocks.isEmpty {
      print("do-not-modify: \(blocks.joined(separator: ", "))")
    }
  }
  if !note.isEmpty { print("note: \(note.joined(separator: " "))") }

  if appendAgency {
    let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    try ToolUsePolicy.guardAllowed(.agencyLogWrite, under: repoRoot)
    let summaryLine = try makeStatusSummary(from: defaultHeartbeatPath)
      .split(separator: "\n").dropFirst().joined(separator: "; ")
    try appendAgencyTriad(summary: summaryLine, kind: "log", details: [], slug: slug)
  }
  print(
    "\nHint: run 'clia core show-environment --format text' for a full workspace overview."
  )
}

private func performWinddownRitual(
  message: [String], onDeck: [String], appendJournal: Bool, dirsTouched: [String], slug: String?
) throws {
  let msg = message.joined(separator: " ")
  guard !msg.isEmpty else { throw ValidationError("--message is required") }

  let fm = FileManager.default
  let repoRoot = URL(fileURLWithPath: fm.currentDirectoryPath)
  let heartbeatPath = repoRoot.appendingPathComponent(defaultHeartbeatPath).path
  let heartbeatExists = fm.fileExists(atPath: heartbeatPath)

  if !heartbeatExists {
    print("[info] heartbeat missing at \(heartbeatPath); winddown will log with 'unknown' start time.")
  }

  let startedAtISO =
    HeartbeatProbe.startedAtISO8601(at: heartbeatPath)
    ?? ISO8601DateFormatter().string(from: Date())
  let tagsJoined =
    loadHeartbeatTags(at: heartbeatPath)?.joined(separator: ",")
    ?? "winddown,summary"

  // Policy check and agency triad append (ContributionEntry)
  try ToolUsePolicy.guardAllowed(.agencyLogWrite, under: repoRoot)
  var detailLines: [String] = []
  if !tagsJoined.isEmpty { detailLines.append("tags: \(tagsJoined)") }
  detailLines.append(contentsOf: onDeck.map { "on-deck: \($0)" })
  try appendAgencyTriad(summary: msg, kind: "log", details: detailLines, slug: slug)
  print("Winddown logged to agency triad (startedAt: \(startedAtISO))")

  if !onDeck.isEmpty { try updateTomorrowNote(onDeck: onDeck) }

  // Optional: append JSON journal entry
  if appendJournal {
    _ = try JournalWriter.append(
      slug: slug ?? (resolvePreferredAgentSlug() ?? "patch"),
      workingDirectory: repoRoot,
      agentVersion: nil,
      highlights: [msg],
      focus: [],
      nextSteps: onDeck,
      signature: "auto",
      dirsTouched: dirsTouched.isEmpty ? nil : dirsTouched
    )
  }
  print(
    "\nHint: run 'clia core show-environment --format text' for a full workspace overview."
  )
}

// Timer migration note removed; rely on heartbeat if present, otherwise continue with warnings.

// MARK: - Incident banner loader

private func loadActiveIncidentBanner() -> Incident? {
  let fm = FileManager.default
  let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
  guard let root = findRepoRoot(startingAt: cwd) else { return nil }
  let url = root.appendingPathComponent(".clia/incidents/active.json")
  guard fm.fileExists(atPath: url.path), let data = fm.contents(atPath: url.path) else {
    return nil
  }
  return try? JSONDecoder().decode(Incident.self, from: data)
}

// MARK: - Agency triad logging (0.4.0 ContributionEntry)

private func appendAgencyTriad(summary: String, kind: String, details: [String], slug: String?)
  throws
{
  guard let s = slug ?? resolvePreferredAgentSlug() else {
    throw ValidationError("Unable to resolve agent slug under .clia/agents")
  }
  let fm = FileManager.default
  let root = URL(fileURLWithPath: fm.currentDirectoryPath)
  let agents = root.appendingPathComponent(".clia/agents")
  let file = agencyTriadPath(for: s, agentsRoot: agents)
  guard fm.fileExists(atPath: file.path) else {
    throw ValidationError("Agency triad not found for slug=\(s): \(file.path)")
  }
  let now = ISO8601DateFormatter().string(from: Date())
  let data = try Data(contentsOf: file)
  var doc = try JSONDecoder().decode(AgencyDoc.self, from: data)
  let entry = AgencyEntry(
    timestamp: now,
    kind: kind,
    title: (kind == "log" ? nil : kind.capitalized),
    summary: summary,
    details: details.isEmpty ? nil : details,
    tags: nil,
    links: nil,
    contributionGroups: [
      ContributionGroup(
        by: s, types: [ContributionItem(type: kind, weight: 1, evidence: summary)])
    ],
    extensions: nil
  )
  doc.entries.append(entry)
  // Newest-first
  doc.entries.sort { $0.timestamp > $1.timestamp }
  doc.updated = now
  try JSON.FileWriter.write(doc, to: file, encoder: JSON.Formatting.humanEncoder)
}

private func resolvePreferredAgentSlug() -> String? {
  // Preference order: patch, codex, clia, else first child under .clia/agents
  let fm = FileManager.default
  let root = URL(fileURLWithPath: fm.currentDirectoryPath)
  let agents = root.appendingPathComponent(".clia/agents")
  let preferred = ["patch", "codex", "clia"]
  for s in preferred {
    let p = agencyTriadPath(for: s, agentsRoot: agents)
    if fm.fileExists(atPath: p.path) { return s }
  }
  if let kids = try? fm.contentsOfDirectory(atPath: agents.path) {
    for k in kids where !k.hasPrefix("_") {
      let p = agencyTriadPath(for: k, agentsRoot: agents)
      if fm.fileExists(atPath: p.path) { return k }
    }
  }
  return nil
}

private func loadHeartbeatTags(at path: String) -> [String]? {
  guard let data = FileManager.default.contents(atPath: path),
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else { return nil }
  return json["tags"] as? [String]
}

private func updateTodayNote(
  using startedAtISO: String?, kawaraStyle: Bool, did: [String], news: String?,
) throws {
  let wakeDate = parseISO8601(startedAtISO) ?? Date()
  let localWake = formatLocalTime(date: wakeDate, kawara: kawaraStyle)
  let dayString = isoDateOnly(from: wakeDate)
  let year = String(dayString.prefix(4))
  let notesDirectory = URL(fileURLWithPath: "notes/")
  let targetDir = notesDirectory.appendingPathComponent(year, isDirectory: true)
  let targetFile = targetDir.appendingPathComponent("\(dayString).md")

  try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

  if !FileManager.default.fileExists(atPath: targetFile.path) {
    let renderedRaw: String =
      renderDailyNoteTemplate(dayString: dayString)
      ?? renderFileSystemTemplate(dayString: dayString)
      ?? "# \(dayString)\n\n## Already did today\n\n-\n"
    let rendered = ensureJSONFrontMatter(
      in: renderedRaw, dayString: dayString, templateId: "daily.v1",
    )
    try rendered.write(to: targetFile, atomically: true, encoding: .utf8)
  }

  let content = (try? String(contentsOf: targetFile, encoding: .utf8)) ?? ""
  let updated = insertOrUpdateAlreadyDid(in: content, wake: localWake, did: did, news: news)
  try updated.write(to: targetFile, atomically: true, encoding: .utf8)
}

private func parseISO8601(_ s: String?) -> Date? {
  guard var raw = s else { return nil }
  if raw.hasSuffix("Z") {
    raw.removeLast()
    raw += "+00:00"
  }
  return ISO8601DateFormatter().date(from: raw) ?? ISO8601DateFormatter().date(from: s ?? "")
}

private func formatLocalTime(date: Date, kawara: Bool) -> String {
  let fmt = DateFormatter()
  fmt.locale = Locale(identifier: "en_US_POSIX")
  fmt.timeZone = .current
  fmt.dateFormat = kawara ? "h:mm a z" : "h:mm a z"
  var t = fmt.string(from: date)
  if kawara {
    t = t.replacingOccurrences(of: ".m.", with: ".M.")
    return "I WOKE UP AT \(t.uppercased())"
  }
  return t
}

private func insertOrUpdateAlreadyDid(in text: String, wake: String, did: [String], news: String?)
  -> String
{
  let heading = "## Already did today"
  let wokePrefix = "- Woke up:"
  var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
  var startIdx: Int
  if let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == heading }) {
    startIdx = idx
  } else {
    if !lines.isEmpty, lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    {
      lines.append("")
    }
    lines.append(heading)
    lines.append("")
    startIdx = lines.count - 2
  }
  var endIdx = lines.count
  if let next = lines[(startIdx + 1)...].firstIndex(where: { $0.hasPrefix("## ") }) {
    endIdx = next
  }
  var section = Array(lines[(startIdx + 1)..<endIdx])
  while section.first.map({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) == true {
    section.removeFirst()
  }

  var newSection: [String] = []
  var existingDid: [String] = []
  var i = 0
  while i < section.count {
    let line = section[i]
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix(wokePrefix) {
      i += 1
      continue
    }
    if trimmed == "- Activities so far:" {
      i += 1
      while i < section.count, section[i].hasPrefix("  - ") {
        let bullet = String(section[i].dropFirst(4))
        if !bullet.isEmpty { existingDid.append(bullet) }
        i += 1
      }
      continue
    }
    if trimmed.hasPrefix("- News:") {
      i += 1
      continue
    }
    newSection.append(line)
    i += 1
  }
  newSection.insert("- Woke up: \(wake)", at: 0)
  var mergedDid: [String] = []
  var seen = Set<String>()
  for d in existingDid + did {
    if d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
    if seen.insert(d).inserted { mergedDid.append(d) }
  }
  if !mergedDid.isEmpty {
    newSection.insert("- Activities so far:", at: 1)
    var insertAt = 2
    for item in mergedDid {
      newSection.insert("  - \(item)", at: insertAt)
      insertAt += 1
    }
  }
  if let newsText = news, !newsText.isEmpty { newSection.append("- News: \(newsText)") }
  if newSection.last.map({ !$0.isEmpty }) ?? false { newSection.append("") }
  var result: [String] = []
  result.append(contentsOf: lines[..<(startIdx + 1)])
  result.append(contentsOf: newSection)
  result.append(contentsOf: lines[endIdx...])
  return result.joined(separator: "\n")
}

private func renderDailyNoteTemplate(dayString: String) -> String? {
  // Load Stencil template from bundle resources
  guard
    let url = Bundle.module.url(
      forResource: "daily.v1.md", withExtension: "stencil", subdirectory: "templates",
    ), let tpl = try? String(contentsOf: url, encoding: .utf8)
  else { return nil }
  let env = Environment()
  let ctx: [String: Any] = ["date": dayString]
  return try? env.renderTemplate(string: tpl, context: ctx)
}

private func renderFileSystemTemplate(dayString: String) -> String? {
  // Legacy fallback: notes/daily-note-template.md with placeholder header
  let templateURL = URL(fileURLWithPath: "notes/daily-note-template.md")
  guard let data = try? Data(contentsOf: templateURL),
    var text = String(data: data, encoding: .utf8)
  else { return nil }
  text = text.replacingOccurrences(of: "# YYYY-MM-DD", with: "# \(dayString)")
  return text
}

// Front matter processing (JSON only)
private struct DailyFrontMatter: Codable {
  var template: String?
  var date: String?
}

private func ensureJSONFrontMatter(in text: String, dayString: String, templateId: String) -> String
{
  guard let range = frontMatterJSONRange(in: text),
    let data = text[range].data(using: .utf8),
    var fm = try? JSONDecoder().decode(DailyFrontMatter.self, from: data)
  else {
    // Prepend JSON front matter block
    let fm = DailyFrontMatter(template: templateId, date: dayString)
    guard let data = try? JSONEncoder().encode(fm),
      let json = String(data: data, encoding: .utf8)
    else { return text }
    guard text.hasPrefix("\n") else { return json + "\n\n" + text }
    return json + text
  }
  var changed = false
  if fm.date != dayString {
    fm.date = dayString
    changed = true
  }
  if fm.template == nil {
    fm.template = templateId
    changed = true
  }
  if changed, let encoded = try? JSONEncoder().encode(fm),
    let json = String(data: encoded, encoding: .utf8)
  {
    var result = text
    result.replaceSubrange(range, with: json)
    return result
  }
  return text
}

private func frontMatterJSONRange(in text: String) -> Range<String.Index>? {
  // Detect a top-of-file JSON object: starts with '{' (ignoring BOM/whitespace) and ends when braces balance.
  var idx = text.startIndex
  // Skip UTF-8 BOM if present
  if text.hasPrefix("\u{FEFF}") { idx = text.index(idx, offsetBy: 1) }
  // Skip leading whitespace/newlines
  while idx < text.endIndex, text[idx].isWhitespace || text[idx].isNewline {
    idx = text.index(after: idx)
  }
  guard idx < text.endIndex, text[idx] == "{" else { return nil }
  var depth = 0
  var inString = false
  var escape = false
  var i = idx
  while i < text.endIndex {
    let ch = text[i]
    if inString {
      if escape {
        escape = false
      } else if ch == "\\" {
        escape = true
      } else if ch == "\"" {
        inString = false
      }
    } else {
      if ch == "\"" {
        inString = true
      } else if ch == "{" {
        depth += 1
      } else if ch == "}" {
        depth -= 1
        if depth == 0 {
          let end = text.index(after: i)
          return idx..<end
        }
      }
    }
    i = text.index(after: i)
  }
  return nil
}

private func updateTomorrowNote(onDeck: [String]) throws {
  let calendar = Calendar.current
  let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
  let dayString = isoDateOnly(from: tomorrow)
  let year = String(dayString.prefix(4))
  let notesDirectory = URL(fileURLWithPath: "notes/")
  let targetDir = notesDirectory.appendingPathComponent(year, isDirectory: true)
  let targetFile = targetDir.appendingPathComponent("\(dayString).md")
  try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
  if !FileManager.default.fileExists(atPath: targetFile.path) {
    let renderedRaw: String =
      renderDailyNoteTemplate(dayString: dayString)
      ?? renderFileSystemTemplate(dayString: dayString)
      ?? "# \(dayString)\n\n## On deck\n\n-\n"
    let rendered = ensureJSONFrontMatter(
      in: renderedRaw, dayString: dayString, templateId: "daily.v1",
    )
    try rendered.write(to: targetFile, atomically: true, encoding: .utf8)
  }
  let content = (try? String(contentsOf: targetFile, encoding: .utf8)) ?? ""
  let updated = insertOrUpdateOnDeck(in: content, items: onDeck)
  try updated.write(to: targetFile, atomically: true, encoding: .utf8)
}

private func isoDateOnly(from date: Date) -> String {
  let fmt = DateFormatter()
  fmt.calendar = Calendar(identifier: .iso8601)
  fmt.locale = Locale(identifier: "en_US_POSIX")
  fmt.timeZone = .current
  fmt.dateFormat = "yyyy-MM-dd"
  return fmt.string(from: date)
}

private func insertOrUpdateOnDeck(in text: String, items: [String]) -> String {
  let heading = "## On deck"
  var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
  var startIndex: Int
  if let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == heading }) {
    startIndex = idx
  } else {
    if !lines.isEmpty, lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    {
      lines.append("")
    }
    lines.append(heading)
    lines.append("")
    startIndex = lines.count - 2
  }
  var endIndex = lines.count
  if let next = lines[(startIndex + 1)...].firstIndex(where: { $0.hasPrefix("## ") }) {
    endIndex = next
  }
  var section = Array(lines[(startIndex + 1)..<endIndex])
  while section.first.map({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) == true {
    section.removeFirst()
  }
  var existing: [String] = []
  var i = 0
  while i < section.count {
    let line = section[i]
    if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("  - ") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      let bullet = trimmed.drop(while: { $0 == "-" || $0 == "*" || $0 == " " })
      let content = bullet.trimmingCharacters(in: .whitespaces)
      if !content.isEmpty { existing.append(content) }
    }
    i += 1
  }
  var merged: [String] = []
  var seen = Set<String>()
  for v in existing + items where !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
    if seen.insert(v).inserted { merged.append(v) }
  }
  var newSection: [String] = []
  for m in merged {
    newSection.append("- \(m)")
  }
  if newSection.isEmpty { newSection = ["-"] }
  if newSection.last.map({ !$0.isEmpty }) ?? false { newSection.append("") }
  var result: [String] = []
  result.append(contentsOf: lines[..<(startIndex + 1)])
  result.append(contentsOf: newSection)
  result.append(contentsOf: lines[endIndex...])
  return result.joined(separator: "\n")
}

private func makeStatusSummary(from heartbeatPath: String) throws -> String {
  let fm = FileManager.default
  var task = "wc"
  var status: String = HeartbeatProbe.status(at: heartbeatPath) ?? "unknown"
  var startedAt: String = HeartbeatProbe.startedAtISO8601(at: heartbeatPath) ?? "unknown"
  var nextCheckAt = ""
  var pointsEarned: Double = 0
  var pointsManual: Double = 0
  var pointsTotal: Double = 0
  var elapsedSeconds = 0
  if let data = fm.contents(atPath: heartbeatPath),
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  {
    if let t = json["task"] as? String, !t.isEmpty {
      task = t
    } else if let directive = json["directive"] as? String, !directive.isEmpty {
      task = directive
    }
    if let s = json["status"] as? String { status = s }
    if let sa = json["startedAt"] as? String { startedAt = sa }
    if startedAt == "unknown", let ts = json["timestamp"] as? String, !ts.isEmpty {
      startedAt = ts
    }
    if let nc = json["nextCheckAt"] as? String { nextCheckAt = nc }
    if let pe = json["pointsEarned"] as? Double { pointsEarned = pe }
    if let pm = json["pointsManual"] as? Double { pointsManual = pm }
    if let pt = json["pointsTotal"] as? Double { pointsTotal = pt }
    if let el = json["elapsedSeconds"] as? Int { elapsedSeconds = el }
  }
  let local = { (iso: String) -> String in
    guard !iso.isEmpty, iso != "unknown" else { return "unknown" }
    var s = iso
    if s.hasSuffix("Z") {
      s.removeLast()
      s += "+00:00"
    }
    let isoFmt = ISO8601DateFormatter()
    guard let dt = isoFmt.date(from: s) else { return iso }
    let out = DateFormatter()
    out.locale = Locale(identifier: "en_US_POSIX")
    out.timeZone = .current
    out.dateFormat = "yyyy-MM-dd HH:mm:ss z"
    return out.string(from: dt)
  }
  let mm = elapsedSeconds / 60
  let ss = elapsedSeconds % 60
  var lines = [
    "wind check-in — status",
    "task: \(task)",
    "status: \(status)",
    "started: \(local(startedAt))",
  ]
  if !nextCheckAt.isEmpty {
    lines.append("next-check: \(local(nextCheckAt))")
  }
  lines.append(
    contentsOf: [
      "elapsed: \(String(format: "%dm %02ds", mm, ss))",
      String(
        format: "points: earned=%.2f manual=%.2f total=%.2f", pointsEarned, pointsManual,
        pointsTotal,
      ),
    ])
  return lines.joined(separator: "\n")
}

// (removed) AGENCY.md append helpers migrated to triad logging

// findRepoRoot is provided at module scope in Clia.swift
