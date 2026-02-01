import Foundation
import SwiftJSONFormatter

enum FormattingFinalizer {
  static func finalizeJSON(at url: URL) {
    let result = SwiftJSONFormatter.format(paths: [url.path], check: false, writeTo: nil)
    if result.errorCount > 0 {
      fputs("clia: json format failed for \(url.path)\n", stderr)
    }
  }
}
