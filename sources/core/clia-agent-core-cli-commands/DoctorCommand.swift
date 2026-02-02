import ArgumentParser
import CLIAAgentCore
import CLIACore
import Foundation

public struct DoctorCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "doctor",
      abstract:
        "Quick health check for a single agent (triads, lineage, write target, dry-run mirrors/roster)"
    )
  }

  @Option(name: .customLong("slug"), help: "Agent slug to check")
  public var slug: String

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  @Flag(name: .customLong("json"), help: "Emit JSON status")
  public var json: Bool = false

  @Flag(name: .customLong("strict"), help: "Exit non-zero on warnings")
  public var strict: Bool = false

  public init() {}

  public func run() throws {
    let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    var errors: [String] = []
    var warnings: [String] = []
    var info: [String] = []

    // Resolve write target
    var target: WriteTarget?
    do {
      target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
      if let t = target { info.append("repoRoot=\(t.repoRoot.path)") }
    } catch {
      errors.append("write-target: \(error.localizedDescription)")
    }

    // Triads presence
    if let agentDir = target?.agentDir {
      let fm = FileManager.default
      let contents =
        (try? fm.contentsOfDirectory(at: agentDir, includingPropertiesForKeys: nil)) ?? []
      let hasAgent = contents.contains {
        $0.lastPathComponent.hasSuffix(".agent.triad.json") && !$0.lastPathComponent.contains(".agency.")
      }
      let hasAgenda = contents.contains { $0.lastPathComponent.hasSuffix(".agenda.triad.json") }
      let hasAgency = contents.contains { $0.lastPathComponent.hasSuffix(".agency.triad.json") }
      if !hasAgent { errors.append("missing *.agent.triad.json at \(agentDir.path)") }
      if !hasAgenda { errors.append("missing *.agenda.triad.json at \(agentDir.path)") }
      if !hasAgency { errors.append("missing *.agency.triad.json at \(agentDir.path)") }
    }

    // Lineage preview (merge) to catch decode issues
    let merged = Merger.mergeAgent(slug: slug, under: cwd)
    if merged.slug == "unknown" { warnings.append("merge-agent: unknown slug (no sources found)") }
    if merged.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      warnings.append("merge-agent: empty title")
    }
    // Classification checks (core fields + default emoji fallback via spec)
    let specEntries = (try? AllContributorsSpecLoader.loadSpec(root: cwd)) ?? [:]
    let mapping: [String: (emoji: String, synonyms: [String])] = specEntries.mapValues {
      ($0.emoji, $0.synonyms ?? [])
    }
    let rawTypes = ContributionMixSupport.contributionTypes(from: merged.contributionMix)
    let (normTypes, unknownTypes) = canonicalizeTypes(rawTypes, with: mapping)
    let derived = derivedEmojis(from: normTypes, with: mapping)
    if normTypes.isEmpty {
      warnings.append("contribution-types: missing or unrecognized for slug=\(slug)")
    }
    if !unknownTypes.isEmpty {
      warnings.append(
        "contribution-types: unknown types \(unknownTypes.sorted().joined(separator: ","))")
    }
    if merged.emojiTags.isEmpty && derived.isEmpty {
      warnings.append("emoji-tags: missing and no default mapping for slug=\(slug)")
    }

    // Persona + System-Instructions existence (inheritance-aware)
    if let t = target {
      func resolve(_ p: String?) -> URL? {
        guard let s = p, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
          return nil
        }
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return URL(string: s) }
        return t.repoRoot.appendingPathComponent(s)
      }
      // Persona
      if let personaPath = merged.persona?.profilePath {
        if let url = resolve(personaPath) {
          if url.isFileURL {
            if !FileManager.default.fileExists(atPath: url.path) {
              warnings.append("persona: missing file at \(personaPath)")
            } else {
              info.append("persona=\(personaPath)")
            }
          } else {
            info.append("persona=url=\(personaPath)")
          }
        }
      } else {
        warnings.append("persona: missing (no profilePath)")
      }
      // System-instructions
      let sys = merged.systemInstructions
      if (sys?.compactPath ?? "").isEmpty && (sys?.fullPath ?? "").isEmpty {
        warnings.append("system-instructions: missing (no compact/full)")
      } else {
        if let cp = sys?.compactPath, let url = resolve(cp) {
          if url.isFileURL && !FileManager.default.fileExists(atPath: url.path) {
            warnings.append("system-instructions.compactPath missing at \(cp)")
          } else {
            info.append("systemInstructions.compact=\(cp)")
          }
        }
        if let fp = sys?.fullPath, let url = resolve(fp) {
          if url.isFileURL && !FileManager.default.fileExists(atPath: url.path) {
            warnings.append("system-instructions.fullPath missing at \(fp)")
          } else {
            info.append("systemInstructions.full=\(fp)")
          }
        }
      }
      // CLI Spec
      if let spec = merged.cliSpec, spec.export {
        if let url = resolve(spec.path) {
          if url.isFileURL && !FileManager.default.fileExists(atPath: url.path) {
            warnings.append("cliSpec: export=true but path missing at \(spec.path ?? "<nil>")")
          } else if let p = spec.path {
            info.append("cliSpec.path=\(p)")
          }
        } else {
          warnings.append("cliSpec: export=true but no path set")
        }
      }
    }

    // Dry-run mirrors (filter to this agent)
    if let t = target {
      let outputs = try? MirrorRenderer.mirrorAgents(at: t.agentsRoot, dryRun: true)
      let planned = (outputs ?? []).filter { $0.path.contains("/\(slug)/") }
      info.append("mirrors.planned=\(planned.count)")
    }

    // Roster check (row presence)
    if let repoRoot = target?.repoRoot {
      let roster = repoRoot.appendingPathComponent("AGENTS.md")
      if let text = try? String(contentsOf: roster, encoding: .utf8), !text.isEmpty {
        let row =
          "| \(merged.title) | \(merged.purpose ?? merged.title) | `.clia/agents/\(slug)/` |"
        if !text.contains(".clia/agents/\(slug)/") {
          warnings.append("roster: row not found for slug=\(slug)")
        } else if !text.contains(row) {
          warnings.append("roster: row present but summary/title may differ")
        }
      } else {
        warnings.append("roster: AGENTS.md missing at repo root")
      }
    }

    if json {
      let dict: [String: Any] = [
        "slug": slug,
        "path": cwd.path,
        "status": (errors.isEmpty && (strict ? warnings.isEmpty : true)) ? "ok" : "degraded",
        "errors": errors,
        "warnings": warnings,
        "info": info,
      ]
      let data = try JSONSerialization.data(
        withJSONObject: dict, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
      if let s = String(data: data, encoding: .utf8) { print(s) }
    } else {
      if !errors.isEmpty { for e in errors { fputs("[error] \(e)\n", stderr) } }
      if !warnings.isEmpty { for w in warnings { fputs("[warn] \(w)\n", stderr) } }
      for i in info { print("[info] \(i)") }
      if errors.isEmpty && (strict ? warnings.isEmpty : true) {
        print("ok: doctor passed for \(slug)")
      }
    }

    if !errors.isEmpty || (strict && !warnings.isEmpty) { throw ExitCode(1) }
  }
}

// MARK: - Local helpers (mirror RosterResolveCommand)
private func canonicalizeTypes(
  _ types: Set<String>, with spec: [String: (emoji: String, synonyms: [String])]
) -> (recognized: Set<String>, unknown: Set<String>) {
  var recognized = Set<String>()
  var unknown = Set<String>()
  let synToKey: [String: String] = spec.reduce(into: [:]) { acc, kv in
    acc[kv.key.lowercased()] = kv.key
    for s in kv.value.synonyms { acc[s.lowercased()] = kv.key }
  }
  for raw in types {
    let key = raw.lowercased()
    if let canon = synToKey[key] {
      recognized.insert(canon)
    } else {
      unknown.insert(raw)
    }
  }
  return (recognized, unknown)
}

private func derivedEmojis(
  from types: Set<String>, with spec: [String: (emoji: String, synonyms: [String])]
) -> Set<String> {
  var out = Set<String>()
  for t in types {
    if let e = spec[t]?.emoji { out.insert(e) }
  }
  return out
}
