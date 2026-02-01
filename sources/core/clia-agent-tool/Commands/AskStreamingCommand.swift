import ArgumentParser

extension Clia {
  // Wrapper; forwards to Ask with --stream. Kept for discoverability.
  struct ChatStreaming: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
      commandName: "chat-streaming",
      abstract: "Stream chat responses (alias for: clia chat --stream)",
    )

    mutating func run() async throws {
      var args = Array(CommandLine.arguments)
      if !args.contains("chat") { args.insert("chat", at: 1) }
      if !args.contains("--stream") { args.append("--stream") }
      let argv = Array(args.dropFirst())
      var command = try Clia.parseAsRoot(argv)
      try command.run()
    }
  }
}
