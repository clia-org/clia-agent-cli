import ArgumentParser
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct MentionsCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "mentions",
      abstract: "List or resolve agent mentions (badge/role/slug)",
      subcommands: [List.self, Resolve.self]
    )
  }
  public init() {}
}

extension MentionsCommand {
  public struct List: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "list", abstract: "List available agent mentions (slug, role, badge)")
    }
    public init() {}
    @Option(name: .customLong("path"), help: "Repo root (default: CWD)") public var path: String?
    @Flag(name: .customLong("json"), help: "Emit JSON") public var json: Bool = false

    public func run() throws {
      let fm = FileManager.default
      let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      let items = try collectMentions(under: root)
      if json {
        let data = try JSONSerialization.data(
          withJSONObject: items.map { $0.dictionary }, options: JSON.Formatting.humanOptions)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        for m in items {
          let badge = m.badge ?? ""
          let displayRole = m.displayRole ?? ""
          print("\(m.slug)\t\(displayRole)\t\(badge)")
        }
      }
    }
  }

  public struct Resolve: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "resolve", abstract: "Resolve a mention token to an agent slug")
    }
    public init() {}
    @Option(name: .customLong("token"), help: "Mention token (e.g., [CX], CX, agent:codex, codex)")
    public var token: String
    @Option(name: .customLong("path"), help: "Repo root (default: CWD)") public var path: String?
    @Flag(name: .customLong("json"), help: "Emit JSON") public var json: Bool = false

    public func run() throws {
      let fm = FileManager.default
      let root = URL(fileURLWithPath: path ?? fm.currentDirectoryPath)
      let items = try collectMentions(under: root)
      let norm = normalize(token)
      let match = items.first { m in
        m.slug == norm || m.displayRole?.lowercased() == norm || m.badge?.lowercased() == norm
          || ("agent:" + m.slug) == token.lowercased()
      }
      if json {
        let out: [String: Any] = [
          "input": token,
          "normalized": norm,
          "matched": match != nil,
          "slug": match?.slug as Any,
          "displayRole": match?.displayRole as Any,
          "badge": match?.badge as Any,
          "path": match?.path as Any,
        ]
        let data = try JSONSerialization.data(
          withJSONObject: out, options: JSON.Formatting.humanOptions)
        if let s = String(data: data, encoding: .utf8) { print(s) }
      } else {
        if let m = match { print(m.slug) } else { print("(no match)") }
      }
    }

    private func normalize(_ s: String) -> String {
      var token = s.trimmingCharacters(in: .whitespacesAndNewlines)
      if token.hasPrefix("^") { token = String(token.dropFirst()) }  // legacy caret
      if token.hasPrefix(">") || token.hasPrefix("<") { token = String(token.dropFirst()) }  // new bring/remove symbols
      token = token.trimmingCharacters(in: .whitespacesAndNewlines)
      let lower = token.lowercased()
      if lower.hasPrefix("agent:") { return String(lower.dropFirst("agent:".count)) }
      if lower.hasPrefix("[") && lower.hasSuffix("]") {
        return String(lower.dropFirst().dropLast())
      }
      return lower
    }
  }
}

private struct MentionItem {
  var slug: String
  var displayRole: String?
  var badge: String?
  var path: String
  var dictionary: [String: Any] {
    ["slug": slug, "displayRole": displayRole as Any, "badge": badge as Any, "path": path]
  }
}

private func collectMentions(under root: URL) throws -> [MentionItem] {
  let fm = FileManager.default
  var out: [MentionItem] = []
  let agentsRoot = root.appendingPathComponent(".clia/agents")
  guard fm.fileExists(atPath: agentsRoot.path) else { return out }
  let agents = try fm.contentsOfDirectory(
    at: agentsRoot, includingPropertiesForKeys: [.isDirectoryKey])
  for dir in agents {
    var isDir: ObjCBool = false
    if !fm.fileExists(atPath: dir.path, isDirectory: &isDir) || !isDir.boolValue { continue }
    // find an *.agent.json file
    if let file = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).first(
      where: { $0.lastPathComponent.contains(".agent.") && $0.pathExtension == "json" })
    {
      if let data = fm.contents(atPath: file.path),
        let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
      {
        let slug = (raw["slug"] as? String) ?? dir.lastPathComponent
        let ext = raw["extensions"] as? [String: Any]
        // Prefer top-level display role
        let displayRole = (raw["role"] as? String)
        let badge = ext?["x-badge"] as? String
        out.append(.init(slug: slug, displayRole: displayRole, badge: badge, path: dir.path))
      }
    }
  }
  return out
}
