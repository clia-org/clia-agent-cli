import Foundation

public enum RosterUpdater {
  public static func update(startingAt: URL, title: String, slug: String, summary: String) throws
    -> URL
  {
    guard let root = WriteTargetResolver.resolveRepoRoot(startingAt: startingAt) else {
      throw NSError(
        domain: "RosterUpdater", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Could not resolve repository root (no .git found above \(startingAt.path))."
        ])
    }
    let rosterURL = root.appendingPathComponent("AGENTS.md")
    let fm = FileManager.default
    let row = "| \(title) | \(singleLine(summary)) | `.clia/agents/\(slug)/` |"
    var contents =
      "# Agents\n\n| Agent | Summary | Path |\n| ----- | ------- | -------- |\n\n\(row)\n"
    if fm.fileExists(atPath: rosterURL.path) {
      let text = try String(contentsOf: rosterURL, encoding: .utf8)
      var lines = text.components(separatedBy: "\n")
      lines.removeAll { $0.contains("_(commissioned via CLI)_") }
      let header = "| ----- | ------- | -------- |"
      if let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == header }) {
        if !lines.contains(row) { lines.insert(row, at: idx + 1) }
      } else {
        lines.append("| Agent | Summary | Path |")
        lines.append(header)
        lines.append(row)
      }
      contents =
        lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }
    try contents.write(to: rosterURL, atomically: true, encoding: .utf8)
    return rosterURL
  }

  private static func singleLine(_ s: String) -> String {
    s.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
