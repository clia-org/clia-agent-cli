import CommonAI
import Foundation

public enum ProviderRole: String, Sendable, Codable {
  case user
  case system
  case model
}

public struct ProviderMessage: Sendable, Equatable, Codable {
  public let role: ProviderRole
  public let text: String
  public init(role: ProviderRole, text: String) {
    self.role = role
    self.text = text
  }

  public static func user(_ text: String) -> ProviderMessage { .init(role: .user, text: text) }
  public static func system(_ text: String) -> ProviderMessage { .init(role: .system, text: text) }
  public static func model(_ text: String) -> ProviderMessage { .init(role: .model, text: text) }
}

public struct ProviderCompletion: Sendable {
  public let message: ProviderMessage
  public let completion: CAICompletion?
  public init(message: ProviderMessage, completion: CAICompletion?) {
    self.message = message
    self.completion = completion
  }
}

public protocol AIProvider {
  func generate(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) async throws -> ProviderMessage

  func generateCompletion(
    messages: [ProviderMessage],
    model: String,
    system: String?
  ) async throws -> ProviderCompletion

  #if canImport(Darwin)
  @available(macOS 12.0, *)
  func stream(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) -> AsyncThrowingStream<ProviderMessage, Error>
  #endif

  func listModels() async throws -> [String]
}

extension AIProvider {
  public func generateCompletion(
    messages: [ProviderMessage],
    model: String,
    system: String?
  ) async throws -> ProviderCompletion {
    let message = try await generate(messages: messages, model: model, system: system)
    return ProviderCompletion(message: message, completion: nil)
  }
}
