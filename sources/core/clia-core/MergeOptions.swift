import CLIACoreModels
import Foundation

public struct MergeOptions: Sendable {
  public var includeSources: Bool
  public var includeDuplicates: Bool
  public init(includeSources: Bool = false, includeDuplicates: Bool = false) {
    self.includeSources = includeSources
    self.includeDuplicates = includeDuplicates
  }
}

// Moved ContextEntry to CLIACoreModels

// MergedAgentView, MergedAgendaView, and MergedAgencyView moved to their own files.
