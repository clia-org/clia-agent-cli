import ArgumentParser
import CLIACore
import Foundation
import WrkstrmFoundation
import WrkstrmMain

/// Reports contribution coverage for all discovered agents, including missing types and per-
/// directory splits.
public struct RosterCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "roster",
      abstract: "Show contribution coverage for agents and highlight missing types"
    )
  }

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  public enum Format: String, ExpressibleByArgument, CaseIterable { case text, json }

  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  @Flag(
    name: .customLong("require-complete"),
    help: "Return a non-zero exit status when canonical contribution types are missing"
  )
  public var requireComplete: Bool = false

  public init() {}

  public func run() throws {
    let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    let report = try buildRosterReport(root: root)
    switch format {
    case .text:
      print(renderRosterText(report: report))
    case .json:
      print(try renderRosterJSON(report: report))
    }
    if requireComplete, !report.missingTypes.isEmpty {
      throw ExitCode(1)
    }
  }
}

// MARK: - Report building

struct RosterReport {
  struct SegmentReport {
    var label: String
    var path: String
    var types: [String: Set<String>]
    var unknownTypes: [String: Set<String>]
    var missingTypes: Set<String>
    var agentSlugs: Set<String>
    var primaryShares: [String: Double]
    var secondaryShares: [String: Double]
  }

  var overallTypes: [String: Set<String>]
  var unknownTypes: [String: Set<String>]
  var missingTypes: Set<String>
  var segments: [SegmentReport]
  var agentSlugs: Set<String>
  var canonicalTypes: Set<String>
  var emojiByType: [String: String]
  var primaryShares: [String: Double]
  var secondaryShares: [String: Double]
}

private struct AgentRecord: Hashable {
  var slug: String
  var segmentLabel: String
  var segmentPath: String
  var baseRoot: URL
}

func buildRosterReport(root: URL) throws -> RosterReport {
  let spec = try AllContributorsSpecLoader.loadSpec(root: root)
  let canonicalTypes = Set(spec.keys)
  let canonicalLookup = buildCanonicalLookup(spec: spec)
  let emojiByType = spec.mapValues { $0.emoji }

  let records = findAgentRecords(under: root)
  var overallTypes: [String: Set<String>] = [:]
  var overallUnknown: [String: Set<String>] = [:]
  var overallSlugs = Set<String>()
  var segments: [String: SegmentAccumulator] = [:]
  var overallPrimaryShares: [String: Double] = [:]
  var overallSecondaryShares: [String: Double] = [:]

  for record in records {
    let merged = Merger.mergeAgent(slug: record.slug, under: record.baseRoot)
    if merged.slug == "unknown" { continue }
    overallSlugs.insert(merged.slug)

    var recognized = Set<String>()
    var unknown = Set<String>()
    var shareByCanon: [String: Double] = [:]
    var secondaryShareByCanon: [String: Double] = [:]

    if let mix = merged.contributionMix {
      let primaryShares = ContributionMixSupport.normalizedPrimaryShares(
        slug: record.slug, under: root)
      let secondaryShares = mix.normalizedSecondary() ?? [:]
      for contribution in mix.primary {
        let trimmed = contribution.type.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }
        if let canon = canonicalType(for: trimmed, lookup: canonicalLookup) {
          recognized.insert(canon)
        } else {
          unknown.insert(trimmed)
        }
      }
      if let secondary = mix.secondary {
        for contribution in secondary {
          let trimmed = contribution.type.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !trimmed.isEmpty else { continue }
          if let canon = canonicalType(for: trimmed, lookup: canonicalLookup) {
            recognized.insert(canon)
          } else {
            unknown.insert(trimmed)
          }
        }
      }
      for (raw, share) in primaryShares {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }
        if let canon = canonicalType(for: trimmed, lookup: canonicalLookup) {
          shareByCanon[canon, default: 0] += share
          recognized.insert(canon)
        } else {
          unknown.insert(trimmed)
        }
      }
      for (raw, share) in secondaryShares {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }
        if let canon = canonicalType(for: trimmed, lookup: canonicalLookup) {
          secondaryShareByCanon[canon, default: 0] += share
          recognized.insert(canon)
        } else {
          unknown.insert(trimmed)
        }
      }
    }

    var seg = segments[
      record.segmentLabel,
      default: SegmentAccumulator(
        label: record.segmentLabel,
        path: record.segmentPath
      )]
    seg.agentSlugs.insert(merged.slug)

    for type in recognized {
      overallTypes[type, default: []].insert(merged.slug)
      seg.types[type, default: []].insert(merged.slug)
    }
    for (type, share) in shareByCanon {
      overallPrimaryShares[type, default: 0] += share
      seg.primaryShares[type, default: 0] += share
    }
    for (type, share) in secondaryShareByCanon {
      overallSecondaryShares[type, default: 0] += share
      seg.secondaryShares[type, default: 0] += share
    }
    for rawUnknown in unknown {
      overallUnknown[rawUnknown, default: []].insert(merged.slug)
      seg.unknownTypes[rawUnknown, default: []].insert(merged.slug)
    }

    segments[record.segmentLabel] = seg
  }

  let overallMissing = canonicalTypes.subtracting(overallTypes.keys)
  let segmentReports: [RosterReport.SegmentReport] = segments
    .values
    .sorted { lhs, rhs in
      if lhs.label == "root" { return true }
      if rhs.label == "root" { return false }
      return lhs.label < rhs.label
    }
    .map { accumulator in
      let missing = canonicalTypes.subtracting(accumulator.types.keys)
      return RosterReport.SegmentReport(
        label: accumulator.label,
        path: accumulator.path,
        types: accumulator.types,
        unknownTypes: accumulator.unknownTypes,
        missingTypes: missing,
        agentSlugs: accumulator.agentSlugs,
        primaryShares: accumulator.primaryShares,
        secondaryShares: accumulator.secondaryShares
      )
    }

  return RosterReport(
    overallTypes: overallTypes,
    unknownTypes: overallUnknown,
    missingTypes: overallMissing,
    segments: segmentReports,
    agentSlugs: overallSlugs,
    canonicalTypes: canonicalTypes,
    emojiByType: emojiByType,
    primaryShares: overallPrimaryShares,
    secondaryShares: overallSecondaryShares
  )
}

private struct SegmentAccumulator {
  var label: String
  var path: String
  var types: [String: Set<String>] = [:]
  var unknownTypes: [String: Set<String>] = [:]
  var agentSlugs: Set<String> = []
  var primaryShares: [String: Double] = [:]
  var secondaryShares: [String: Double] = [:]
}

private func buildCanonicalLookup(spec: [String: AllContributorsSpecEntry])
  -> [String: String]
{
  var out: [String: String] = [:]
  for (key, entry) in spec {
    let lowered = key.lowercased()
    out[lowered] = key
    out[lowered.replacingOccurrences(of: " ", with: "-")] = key
    out[lowered.replacingOccurrences(of: "_", with: "-")] = key
    if let synonyms = entry.synonyms {
      for syn in synonyms {
        let normalized = syn.lowercased()
        out[normalized] = key
        out[normalized.replacingOccurrences(of: " ", with: "-")] = key
        out[normalized.replacingOccurrences(of: "_", with: "-")] = key
      }
    }
  }
  return out
}

private func canonicalType(for raw: String, lookup: [String: String]) -> String? {
  let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty else { return nil }
  let lower = trimmed.lowercased()
  if let hit = lookup[lower] { return hit }
  let hyphenated = lower.replacingOccurrences(of: " ", with: "-")
  if let hit = lookup[hyphenated] { return hit }
  let underscored = hyphenated.replacingOccurrences(of: "_", with: "-")
  if let hit = lookup[underscored] { return hit }
  return nil
}

private func findAgentRecords(under root: URL) -> [AgentRecord] {
  var out: [AgentRecord] = []
  var seen = Set<AgentRecord>()
  let fm = FileManager.default

  func appendAgents(at baseRoot: URL) {
    let agentsDir = baseRoot.appendingPathComponent(".clia/agents")
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: agentsDir.path, isDirectory: &isDir), isDir.boolValue else {
      return
    }
    guard let kids = try? fm.contentsOfDirectory(at: agentsDir, includingPropertiesForKeys: nil)
    else {
      return
    }
    let label = segmentLabel(for: baseRoot, root: root)
    let path = baseRoot.standardizedFileURL.path
    for child in kids where child.hasDirectoryPath {
      // Ignore historical archives that are not active agents
      if child.lastPathComponent == "legacy-imports" { continue }
      // Exclude root-profile directory from roster listings; its attributes are
      // inherited by concrete agents via triad merging but should not appear as
      // a standalone agent in coverage reports.
      if child.lastPathComponent == "_root" { continue }
      let record = AgentRecord(
        slug: child.lastPathComponent,
        segmentLabel: label,
        segmentPath: path,
        baseRoot: baseRoot
      )
      if seen.insert(record).inserted {
        out.append(record)
      }
    }
  }

  appendAgents(at: root)

  let gitmodules = root.appendingPathComponent(".gitmodules")
  if let contents = try? String(contentsOf: gitmodules, encoding: .utf8) {
    for raw in contents.components(separatedBy: .newlines) {
      let line = raw.trimmingCharacters(in: .whitespaces)
      guard line.hasPrefix("path") else { continue }
      let parts = line.split(separator: "=", maxSplits: 1).map {
        String($0).trimmingCharacters(in: .whitespaces)
      }
      guard parts.count == 2 else { continue }
      let baseRoot = root.appendingPathComponent(parts[1])
      appendAgents(at: baseRoot)
    }
  }

  return out
}

private func segmentLabel(for baseRoot: URL, root: URL) -> String {
  let rootPath = root.standardizedFileURL.path
  let basePath = baseRoot.standardizedFileURL.path
  if basePath == rootPath { return "root" }
  if basePath.hasPrefix(rootPath + "/") {
    let rel = String(basePath.dropFirst(rootPath.count + 1))
    return rel.isEmpty ? "root" : rel
  }
  return baseRoot.lastPathComponent
}

// MARK: - Rendering helpers

func renderRosterText(report: RosterReport) -> String {
  var lines: [String] = []

  lines.append("== Overall ==")
  lines.append(
    contentsOf: renderTypeLines(
      report.overallTypes, indent: "", emojiMap: report.emojiByType,
      primaryShares: report.primaryShares, secondaryShares: report.secondaryShares))
  lines.append(
    "Summary: types=\(report.overallTypes.count) agents=\(report.agentSlugs.count)"
  )
  lines.append(
    "Missing types (overall): \(formatMissing(report.missingTypes, emojiMap: report.emojiByType))"
  )
  if !report.unknownTypes.isEmpty {
    lines.append(
      "Unknown types: \(formatUnknown(report.unknownTypes))"
    )
  }

  if !report.segments.isEmpty {
    lines.append("")
    lines.append("== Segments ==")
    for segment in report.segments {
      lines.append("Segment \(segment.label) — \(segment.path)")
      if segment.types.isEmpty {
        lines.append("  (no agents)")
      } else {
        lines.append(
          contentsOf: renderTypeLines(
            segment.types, indent: "  ", emojiMap: report.emojiByType,
            primaryShares: segment.primaryShares, secondaryShares: segment.secondaryShares))
      }
      lines.append(
        "  Missing types: \(formatMissing(segment.missingTypes, emojiMap: report.emojiByType))")
      if !segment.unknownTypes.isEmpty {
        lines.append("  Unknown types: \(formatUnknown(segment.unknownTypes))")
      }
      lines.append("")
    }
    if let last = lines.last, last.isEmpty { lines.removeLast() }
  }

  return lines.joined(separator: "\n")
}

func renderRosterJSON(report: RosterReport) throws -> String {
  func convert(_ map: [String: Set<String>]) -> [String: [String]] {
    Dictionary(uniqueKeysWithValues: map.map { ($0.key, Array($0.value).sorted()) })
  }

  func convertShares(_ map: [String: Double]) -> [String: Double] {
    Dictionary(
      uniqueKeysWithValues: map.sorted { $0.key < $1.key }.map { key, value in
        (key, Double(round(value * 1000) / 1000))
      })
  }

  let segmentsJSON: [[String: Any]] = report.segments.map { segment in
    [
      "label": segment.label,
      "path": segment.path,
      "types": convert(segment.types),
      "missingTypes": Array(segment.missingTypes).sorted(),
      "unknownTypes": convert(segment.unknownTypes),
      "primaryShares": convertShares(segment.primaryShares),
      "secondaryShares": convertShares(segment.secondaryShares),
      "totals": [
        "types": segment.types.count,
        "agents": segment.agentSlugs.count,
      ],
    ]
  }

  let payload: [String: Any] = [
    "types": convert(report.overallTypes),
    "totals": [
      "types": report.overallTypes.count,
      "agents": report.agentSlugs.count,
    ],
    "missingTypes": Array(report.missingTypes).sorted(),
    "unknownTypes": convert(report.unknownTypes),
    "segments": segmentsJSON,
    "canonicalTypes": Array(report.canonicalTypes).sorted(),
    "emojis": report.emojiByType,
    "primaryShares": convertShares(report.primaryShares),
    "secondaryShares": convertShares(report.secondaryShares),
    "roster": [] as [String],
  ]

  let data = try JSONSerialization.data(
    withJSONObject: payload, options: JSON.Formatting.humanOptions)
  guard let output = String(data: data, encoding: .utf8) else {
    throw CocoaError(.coderInvalidValue)
  }
  return output
}

private func renderTypeLines(
  _ map: [String: Set<String>], indent: String, emojiMap: [String: String],
  primaryShares: [String: Double], secondaryShares: [String: Double]
) -> [String] {
  map
    .sorted { lhs, rhs in
      let diff = rhs.value.count - lhs.value.count
      if diff == 0 { return lhs.key < rhs.key }
      return diff > 0
    }
    .map { entry in
      let slugs = Array(entry.value).sorted().joined(separator: ", ")
      let typeLabel = decoratedType(entry.key, emojiMap: emojiMap)
      let primarySuffix = primaryShares[entry.key].map { "Σ=\(formatShare($0))" }
      let secondarySuffix = secondaryShares[entry.key].map { "Σ₂=\(formatShare($0))" }
      let suffixComponents = [primarySuffix, secondarySuffix].compactMap { $0 }
      let suffix = suffixComponents.isEmpty ? "" : ", " + suffixComponents.joined(separator: ", ")
      return "\(indent)- \(typeLabel) (\(entry.value.count)\(suffix)): \(slugs)"
    }
}

private func formatMissing(_ missing: Set<String>, emojiMap: [String: String]) -> String {
  guard !missing.isEmpty else { return "None" }
  let decorated = missing.map { decoratedType($0, emojiMap: emojiMap) }.sorted()
  return decorated.joined(separator: ", ")
}

private func formatUnknown(_ unknown: [String: Set<String>]) -> String {
  let parts =
    unknown
    .sorted { $0.key < $1.key }
    .map { key, slugs in
      "\(key) ↦ \(Array(slugs).sorted().joined(separator: ", "))"
    }
  return parts.joined(separator: "; ")
}

private func decoratedType(_ type: String, emojiMap: [String: String]) -> String {
  if let emoji = emojiMap[type], !emoji.isEmpty {
    return "\(emoji) \(type)"
  }
  return type
}

private func formatShare(_ share: Double) -> String {
  String(format: "%.2f", share)
}
