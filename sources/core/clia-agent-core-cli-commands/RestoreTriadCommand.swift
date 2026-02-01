import ArgumentParser
import Foundation

public struct RestoreTriadCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "restore-triad",
      abstract: "Restore triad file(s) from .bak backups for an agent"
    )
  }

  public init() {}

  public enum Kind: String, ExpressibleByArgument, CaseIterable { case agent, agenda, agency, all }

  @Option(name: .customLong("slug"), help: "Agent slug (required)")
  public var slug: String

  @Option(name: .customLong("kind"), help: "Triad kind: agent|agenda|agency|all")
  public var kind: Kind = .all

  @Option(name: .customLong("path"), help: "Repo root (default: CWD)")
  public var path: String?

  @Flag(name: .customLong("apply"), help: "Apply restore (copy .bak over current)")
  public var apply: Bool = false

  @Flag(
    name: .customLong("backup-current"), help: "Backup current to .pre-restore.bak before overwrite"
  )
  public var backupCurrent: Bool = true

  public func run() throws {
    let fm = FileManager.default
    let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
    let dir = root.appendingPathComponent(".clia/agents/\(slug)")
    guard fm.fileExists(atPath: dir.path) else {
      throw ValidationError("Agent dir not found: \(dir.path)")
    }
    let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    var targets: [(bak: URL, cur: URL)] = []
    func want(_ name: String) -> Bool {
      switch kind {
      case .all: return name.contains(".json")
      case .agent: return name.contains(".agent.json")
      case .agenda: return name.contains(".agenda.json")
      case .agency: return name.contains(".agency.json")
      }
    }
    for f in files where f.lastPathComponent.hasSuffix(".bak") {
      let cur = f.deletingPathExtension()
      let name = cur.lastPathComponent
      if want(name) && fm.fileExists(atPath: cur.path) {
        targets.append((bak: f, cur: cur))
      }
    }
    guard !targets.isEmpty else {
      print("[restore-triad] no matching .bak files for slug=\(slug)")
      return
    }
    for t in targets.sorted(by: { $0.cur.path < $1.cur.path }) {
      if apply {
        if backupCurrent {
          let pre = t.cur.deletingLastPathComponent().appendingPathComponent(
            t.cur.lastPathComponent + ".pre-restore.bak")
          try? fm.removeItem(at: pre)
          if let data = try? Data(contentsOf: t.cur) { try data.write(to: pre) }
        }
        try? fm.removeItem(at: t.cur)
        try fm.copyItem(at: t.bak, to: t.cur)
        print("[restore-triad] restored: \(t.cur.path)")
      } else {
        print("[restore-triad] would-restore: \(t.cur.path) ← \(t.bak.lastPathComponent)")
      }
    }
  }
}
