import CLIAAgentCore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

internal enum AgentNormalizeCore {
  @discardableResult
  static func apply(startingAt cwd: URL, slug: String, write: Bool) throws -> (
    changed: Bool, path: URL
  ) {
    let target = try WriteTargetResolver.resolve(for: slug, startingAt: cwd)
    let url = triadPath(in: target.agentDir, slug: slug, kind: "agent")
    let changed = try applyFile(url: url, write: write)
    return (changed, url)
  }

  @discardableResult
  static func applyFile(url: URL, write: Bool) throws -> Bool {
    let fm = FileManager.default
    guard fm.fileExists(atPath: url.path) else { return false }
    let originalData = try Data(contentsOf: url)
    var doc = try JSONDecoder().decode(AgentDoc.self, from: originalData)

    let origLinks = doc.links
    let origExts = doc.extensions

    // Sort links by title asc (case-insensitive), nil titles last; tie-break by url asc (nil last)
    doc.links = sortLinks(origLinks)

    // Sort extensions.operationModes if it is an array of strings
    if var exts = origExts, let sorted = sortOperationModes(exts["operationModes"]) {
      exts["operationModes"] = .array(sorted.map { .string($0) })
      doc.extensions = exts
    }

    let listChanged =
      !equalLinks(doc.links, origLinks) || !equalOperationModes(doc.extensions, origExts)
    let enc = JSON.Formatting.humanEncoder
    var normalizedData = try enc.encode(doc)
    if normalizedData.last != 0x0A { normalizedData.append(0x0A) }
    let bytesDiffer = normalizedData != originalData
    if write && bytesDiffer {
      try JSON.FileWriter.write(doc, to: url, encoder: enc)
      FormattingFinalizer.finalizeJSON(at: url)
    }
    return listChanged || bytesDiffer
  }

  private static func sortLinks(_ arr: [LinkRef]) -> [LinkRef] {
    return arr.sorted { l, r in
      func norm(_ s: String?) -> String? { s?.lowercased() }
      switch (norm(l.title), norm(r.title)) {
      case (nil, nil): break
      case (nil, _?): return false
      case (_?, nil): return true
      case (let lt?, let rt?):
        if lt != rt { return lt < rt }
      }
      // tie-break by URL (case-insensitive), nil last
      switch (norm(l.url), norm(r.url)) {
      case (nil, nil): return false
      case (nil, _?): return false
      case (_?, nil): return true
      case (let lu?, let ru?): return lu < ru
      }
    }
  }

  private static func sortOperationModes(_ value: ExtensionValue?) -> [String]? {
    guard case .array(let values)? = value else { return nil }
    var strings: [String] = []
    strings.reserveCapacity(values.count)
    for v in values {
      guard case .string(let s) = v else { return nil }
      strings.append(s)
    }
    let sorted = strings.sorted { $0.lowercased() < $1.lowercased() }
    return sorted
  }

  private static func extractOperationModes(_ exts: [String: ExtensionValue]?) -> [String]? {
    guard let exts, case .array(let values)? = exts["operationModes"] else { return nil }
    var out: [String] = []
    for v in values {
      guard case .string(let s) = v else { return nil }
      out.append(s)
    }
    return out
  }

  private static func equalLinks(_ a: [LinkRef], _ b: [LinkRef]) -> Bool {
    guard a.count == b.count else { return false }
    for (l, r) in zip(a, b) where l.title != r.title || l.url != r.url {
      return false
    }
    return true
  }

  private static func equalOperationModes(
    _ a: [String: ExtensionValue]?, _ b: [String: ExtensionValue]?
  ) -> Bool {
    let la = extractOperationModes(a)
    let lb = extractOperationModes(b)
    switch (la, lb) {
    case (nil, nil): return true
    case (nil, _?), (_?, nil): return false
    case (let sa?, let sb?): return sa == sb
    }
  }

  private static func triadPath(in dir: URL, slug: String, kind: String) -> URL {
    let fm = FileManager.default
    if let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      if let match = contents.first(where: { $0.lastPathComponent.hasSuffix(".\(kind).json") }) {
        return match
      }
    }
    let dirTag =
      dir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .lastPathComponent
    return dir.appendingPathComponent("\(slug)@\(dirTag).\(kind).json")
  }
}
