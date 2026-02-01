import CommonAI
import CommonAIGoogle
import Foundation

public struct GeminiProvider: AIProvider {
  private let service: GoogleCommonAIService

  public init(apiKey: String) { service = .init(apiKey: apiKey) }

  public func generate(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) async throws -> ProviderMessage {
    let m = service.model(named: model)
    let content = Self.makeCAIContent(messages: messages, system: system)
    let res = try await m.generate(content)
    return .init(role: .model, text: res.text)
  }

  public func generateCompletion(
    messages: [ProviderMessage],
    model: String,
    system: String?
  ) async throws -> ProviderCompletion {
    let m = service.model(named: model)
    let content = Self.makeCAIContent(messages: messages, system: system)
    let completion = try await m.complete(content)
    let message = ProviderMessage(role: .model, text: completion.primaryMessage.text)
    return ProviderCompletion(message: message, completion: completion)
  }

  #if canImport(Darwin)
  @available(macOS 12.0, *)
  public func stream(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) -> AsyncThrowingStream<ProviderMessage, Error> {
    let m = service.model(named: model)
    let history = Self.makeCAIContent(messages: system.map { [.system($0)] } ?? [], system: nil)
    let payload = Self.makeCAIContent(messages: messages, system: nil)

    return AsyncThrowingStream { continuation in
      Task { @MainActor in
        let chat = m.startChat(history: history)
        let stream = chat.sendStream(payload)
        do {
          for try await r in stream {
            continuation.yield(.init(role: .model, text: r.text))
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
  #endif

  public func listModels() async throws -> [String] {
    try await service.listModels(pageSize: nil).map(\.name)
  }

  private static func makeCAIContent(messages: [ProviderMessage], system: String?) -> [CAIContent] {
    var out: [CAIContent] = []
    if let system, !system.isEmpty { out.append(.system(system)) }
    for m in messages {
      switch m.role {
      case .user: out.append(.user(m.text))
      case .system: out.append(.system(m.text))
      case .model: out.append(.model(m.text))
      }
    }
    return out
  }
}
