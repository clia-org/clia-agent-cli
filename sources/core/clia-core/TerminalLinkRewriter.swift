import SwiftTerminalLinkRewriter

package struct TerminalLinkRewriter {
  package static func rewriteClickableFileReferences(_ text: String) -> String {
    SwiftTerminalLinkRewriter.rewriteClickableFileReferences(text)
  }
}
