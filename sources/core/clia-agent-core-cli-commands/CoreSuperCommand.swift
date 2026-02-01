import ArgumentParser

/// Top-level aggregator for CLIAAgentCore utilities.
/// Exposes the shared commands under `clia core`.
public struct Core: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "core",
      abstract: "Core agent utilities",
      subcommands: agentCoreSubcommands
    )
  }

  public init() {}
}
