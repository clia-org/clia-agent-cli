import Testing

@testable import CLIACore

@Test("TerminalLinkRewriter rewrites path:line into clickable path plus separate line")
func terminalLinkRewriterSplitsLineNumber() {
  let input = """
    - \
    `/Users/example/workspace/clia-agent/sources/core/clia-agent-tool/Clia.swift:74`
    """

  let output = TerminalLinkRewriter.rewriteClickableFileReferences(input)

  #expect(
    output
      == """
      - \
      `/Users/example/workspace/clia-agent/sources/core/clia-agent-tool/Clia.swift`
        line 74
      """
  )
}

@Test("TerminalLinkRewriter keeps fenced code blocks unchanged")
func terminalLinkRewriterDoesNotRewriteInsideFences() {
  let input = """
    ```bash
    echo /Users/example/workspace/code/spm/tools/foundry/README.md:42
    ```
    """

  let output = TerminalLinkRewriter.rewriteClickableFileReferences(input)

  #expect(output == input)
}

@Test("TerminalLinkRewriter supports repo-relative paths")
func terminalLinkRewriterSupportsRepoRelativePaths() {
  let input = "See `code/spm/tools/foundry/README.md:42` for details."
  let output = TerminalLinkRewriter.rewriteClickableFileReferences(input)

  #expect(
    output
      == """
      See `code/spm/tools/foundry/README.md` for details.
      line 42
      """
  )
}

@Test("TerminalLinkRewriter does not rewrite URLs with ports")
func terminalLinkRewriterDoesNotRewriteUrlsWithPorts() {
  let input = "Open https://example.com:443/docs"
  let output = TerminalLinkRewriter.rewriteClickableFileReferences(input)
  #expect(output == input)
}

@Test("TerminalLinkRewriter breaks long URLs onto their own line")
func terminalLinkRewriterBreaksLongUrls() {
  let longUrl = "https://example.com/" + String(repeating: "a", count: 120)
  let input = "- See this link: \(longUrl)"

  let output = TerminalLinkRewriter.rewriteClickableFileReferences(input)

  #expect(
    output
      == """
      - See this link:
        \(longUrl)
      """
  )
}

@Test("TerminalLinkRewriter breaks long /Users paths onto their own line")
func terminalLinkRewriterBreaksLongUsersPaths() {
  let longPath = "/Users/example/" + String(repeating: "b", count: 120) + "/README.md"
  let input = "- 📁 `\(longPath)`"

  let output = TerminalLinkRewriter.rewriteClickableFileReferences(input)

  #expect(
    output
      == """
      - 📁
        `\(longPath)`
      """
  )
}
