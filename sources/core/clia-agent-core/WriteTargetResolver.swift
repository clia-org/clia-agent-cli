import Foundation

public enum WriteScope: String, Sendable { case local, submodule, workspace }

public struct WriteTarget: Sendable {
  public var repoRoot: URL
  public var agentsRoot: URL
  public var agentDir: URL
}

public enum WriteTargetResolver {
  public static func resolveRepoRoot(startingAt url: URL) -> URL? {
    let fm = FileManager.default
    var cur = url
    while true {
      let gitDir = cur.appendingPathComponent(".git", isDirectory: true)
      var isDir: ObjCBool = false
      if fm.fileExists(atPath: gitDir.path, isDirectory: &isDir) { return cur }
      let parent = cur.deletingLastPathComponent()
      if parent.path == cur.path { break }
      cur = parent
    }
    return nil
  }

  public static func resolve(for slug: String, startingAt path: URL, scope: WriteScope = .submodule)
    throws -> WriteTarget
  {
    let fm = FileManager.default
    guard let repoRoot = resolveRepoRoot(startingAt: path) else {
      throw NSError(
        domain: "WriteTargetResolver", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Could not resolve repository root (no .git found above \(path.path)). Pass --path to adjust."
        ])
    }
    let agentsRoot = repoRoot.appendingPathComponent(".clia/agents", isDirectory: true)
    let agentDir = agentsRoot.appendingPathComponent(slug, isDirectory: true)
    if !fm.fileExists(atPath: agentDir.path) {
      try fm.createDirectory(at: agentDir, withIntermediateDirectories: true)
    }
    return WriteTarget(repoRoot: repoRoot, agentsRoot: agentsRoot, agentDir: agentDir)
  }
}
