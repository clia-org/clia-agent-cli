import Foundation

public enum Union {
  /// Order-preserving union of multiple string arrays.
  public static func strings(_ lists: [[String]]) -> [String] {
    var seen = Set<String>()
    var out: [String] = []
    for arr in lists {
      for s in arr where !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        if seen.insert(s).inserted { out.append(s) }
      }
    }
    return out
  }
}
