import ArgumentParser

public enum AgentCoreCommands {
  /// Standard set of shared agent subcommands provided by CLIAAgentCoreCLICommands.
  /// Order: keep stable for CLI help output.
  public static let standard: [ParsableCommand.Type] = [
    MirrorsCommand.self,
    JournalCommand.self,
    RosterCommand.self,
    ToolPolicyCommand.self,
    RosterUpdateCommand.self,
    RosterResolveCommand.self,
    TemplatesCommand.self,
    MixScoreCommand.self,
    TypesListCommand.self,
    DoctorCommand.self,
    ProfileCommand.self,
    LineageLintCommand.self,
    TriadsCommandGroup.self,
    ReloadProfileCommand.self,
    IncidentsCommand.self,
    RecoveryCommand.self,
    WorkspaceValidateCommand.self,
    ShowEnvironmentCommand.self,
    NormalizeSchemaCommand.self,
    BackupCleanupCommand.self,
    DirectoryFlattenCommand.self,
    HeaderCommand.self,
    HeaderTitle.self,
  ]
}

// Top-level convenience for easy appends in client CLIs
public let agentCoreSubcommands: [ParsableCommand.Type] = [
  MirrorsCommand.self,
  JournalCommand.self,
  RosterCommand.self,
  ToolPolicyCommand.self,
  RosterUpdateCommand.self,
  RosterResolveCommand.self,
  TypesListCommand.self,
  MixScoreCommand.self,
  DoctorCommand.self,
  ProfileCommand.self,
  LineageLintCommand.self,
  TriadsCommandGroup.self,
  ReloadProfileCommand.self,
  IncidentsCommand.self,
  RecoveryCommand.self,
  WorkspaceValidateCommand.self,
  ShowEnvironmentCommand.self,
  NormalizeSchemaCommand.self,
  BackupCleanupCommand.self,
  DirectoryFlattenCommand.self,
  HeaderCommand.self,
  HeaderTitle.self,
]
