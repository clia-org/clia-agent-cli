import Foundation

public enum LineageResolver {
  private static func resolveDirectoryIfNeeded(_ url: URL) -> URL? {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: url.path) else { return nil }

    guard let destinationPath = try? fileManager.destinationOfSymbolicLink(atPath: url.path) else {
      var isDirectory: ObjCBool = false
      if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue
      {
        return url
      }
      return nil
    }

    let destinationURL: URL = {
      if destinationPath.hasPrefix("/") {
        return URL(fileURLWithPath: destinationPath)
      }
      return url.deletingLastPathComponent().appendingPathComponent(destinationPath)
    }()

    var destinationIsDirectory: ObjCBool = false
    guard
      fileManager.fileExists(atPath: destinationURL.path, isDirectory: &destinationIsDirectory),
      destinationIsDirectory.boolValue
    else { return nil }

    return destinationURL
  }

  public static func findAgentDirs(for slug: String, under root: URL) -> [ContextItem] {
    let fm = FileManager.default

    // Collect ancestor directories from filesystem root -> `root` (global -> local).
    var ancestors: [URL] = []
    var cur = root
    while true {
      ancestors.append(cur)
      let parent = cur.deletingLastPathComponent()
      if parent.path == cur.path { break }
      cur = parent
    }
    ancestors = ancestors.reversed()

    // Submodules from .gitmodules, but only those that actually CONTAIN `root`.
    // This keeps domain boundaries intact and prevents unrelated sibling submodules
    // from affecting lineage resolution.
    var containingSubmoduleRoots: [URL] = []
    var seenSubPaths = Set<String>()
    let rootPath = root.standardizedFileURL.path
    for ancestor in ancestors {
      for sub in parseGitmodules(at: ancestor) {
        let subURL = sub.standardizedFileURL
        let subPath = subURL.path
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: subPath, isDirectory: &isDir), isDir.boolValue else { continue }
        guard rootPath == subPath || rootPath.hasPrefix(subPath + "/") else { continue }
        if seenSubPaths.insert(subPath).inserted { containingSubmoduleRoots.append(subURL) }
      }
    }
    // Order outermost -> innermost (still global -> local).
    containingSubmoduleRoots.sort { $0.path.count < $1.path.count }

    func agentDoc(in resolvedAgentsDir: URL) -> (agentURL: URL, prefix: String)? {
      let contents = (try? fm.contentsOfDirectory(atPath: resolvedAgentsDir.path)) ?? []
      let candidates = contents
        .filter { $0.hasSuffix(".agent.json") && !$0.contains(".agency.") }
        .sorted()
      guard let agentName = candidates.first else { return nil }
      let agentURL = resolvedAgentsDir.appendingPathComponent(agentName)
      let comps = agentURL.lastPathComponent.split(separator: ".").map(String.init)
      let prefix = comps.first ?? ""
      return (agentURL, prefix)
    }

    var items: [ContextItem] = []
    var weight = 0

    // 1) Global -> local ancestor roots.
    for ancestor in ancestors {
      let agentsDir = ancestor.appendingPathComponent(".clia/agents/\(slug)")
      guard let resolvedAgentsDir = resolveDirectoryIfNeeded(agentsDir) else { continue }
      guard let doc = agentDoc(in: resolvedAgentsDir) else { continue }
      items.append(.init(dir: resolvedAgentsDir, agentURL: doc.agentURL, prefix: doc.prefix, weight: weight))
      weight += 1
    }

    // 2) Domain-local submodule roots that contain `root` (outer -> inner).
    // Avoid duplicating contexts already discovered via the ancestor walk.
    let ancestorPaths = Set(items.map { $0.dir.standardizedFileURL.path })
    for subRoot in containingSubmoduleRoots {
      let agentsDir = subRoot.appendingPathComponent(".clia/agents/\(slug)")
      guard let resolvedAgentsDir = resolveDirectoryIfNeeded(agentsDir) else { continue }
      guard ancestorPaths.contains(resolvedAgentsDir.standardizedFileURL.path) == false else { continue }
      guard let doc = agentDoc(in: resolvedAgentsDir) else { continue }
      items.append(.init(dir: resolvedAgentsDir, agentURL: doc.agentURL, prefix: doc.prefix, weight: weight))
      weight += 1
    }

    // Merge rule is enforced by callers: later contexts are more local. For now, most-local-wins.
    return items
  }

  static func parseGitmodules(at root: URL) -> [URL] {
    let file = root.appendingPathComponent(".gitmodules")
    guard let data = try? Data(contentsOf: file), let s = String(data: data, encoding: .utf8) else {
      return []
    }
    var urls: [URL] = []
    for rawLine in s.components(separatedBy: .newlines) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.isEmpty || line.hasPrefix("#") { continue }
      if line.hasPrefix("path") {
        let parts = line.split(separator: "=", maxSplits: 1).map {
          String($0).trimmingCharacters(in: .whitespaces)
        }
        if parts.count == 2 { urls.append(root.appendingPathComponent(parts[1])) }
      }
    }
    return urls
  }
}
