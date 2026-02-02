import CLIAAgentCore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

internal enum AgencySortCore {
  @discardableResult
  static func apply(startingAt cwd: URL, slug: String, write: Bool) throws -> (
    changed: Bool, path: URL
  ) {
    let fm = FileManager.default
    let target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
    let url = agencyTriadPath(in: target.agentDir, slug: slug)
    guard fm.fileExists(atPath: url.path) else { return (false, url) }
    let originalData = try Data(contentsOf: url)
    var doc = try JSONDecoder().decode(AgencyDoc.self, from: originalData)
    let before = doc.entries
    let after = SortedArray(unsorted: before, sortOrder: { $0.timestamp > $1.timestamp }).elements
    let listChanged =
      !(before.count == after.count
      && zip(before, after).allSatisfy { $0.timestamp == $1.timestamp })
    if listChanged { doc.entries = after }

    let enc = JSON.Formatting.humanEncoder
    var normalized = try enc.encode(doc)
    if normalized.last != 0x0A { normalized.append(0x0A) }
    let bytesDiffer = normalized != originalData
    if write && bytesDiffer {
      try JSON.FileWriter.write(doc, to: url, encoder: enc)
      FormattingFinalizer.finalizeJSON(at: url)
    }
    return (listChanged || bytesDiffer, url)
  }

  @discardableResult
  static func applyFile(url: URL, write: Bool) throws -> Bool {
    let fm = FileManager.default
    guard fm.fileExists(atPath: url.path) else { return false }
    let originalData = try Data(contentsOf: url)
    var doc = try JSONDecoder().decode(AgencyDoc.self, from: originalData)
    let before = doc.entries
    let after = SortedArray(unsorted: before, sortOrder: { $0.timestamp > $1.timestamp }).elements
    let listChanged =
      !(before.count == after.count
      && zip(before, after).allSatisfy { $0.timestamp == $1.timestamp })
    if listChanged { doc.entries = after }

    let enc = JSON.Formatting.humanEncoder
    var normalized = try enc.encode(doc)
    if normalized.last != 0x0A { normalized.append(0x0A) }
    let bytesDiffer = normalized != originalData
    if write && bytesDiffer {
      try JSON.FileWriter.write(doc, to: url, encoder: enc)
      FormattingFinalizer.finalizeJSON(at: url)
    }
    return listChanged || bytesDiffer
  }

  private static func agencyTriadPath(in dir: URL, slug: String) -> URL {
    let fm = FileManager.default
    if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      if let match = contents.first(where: { $0.lastPathComponent.hasSuffix(".agency.triad.json") }) {
        return match
      }
    }
    let dirTag =
      dir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .lastPathComponent
    return dir.appendingPathComponent("\(slug)@\(dirTag).agency.triad.json")
  }
}
