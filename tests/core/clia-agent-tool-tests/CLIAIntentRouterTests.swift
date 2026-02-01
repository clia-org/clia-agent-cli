import Testing

@testable import CLIAAgentTool

struct CLIAIntentRouterTests {
  @Test("route returns chat when no execute prefix is present")
  func routeChatWhenNoPrefix() throws {
    let router = CLIAIntentRouter()
    let intent = try router.route("hello there")
    switch intent {
    case .chat(let text):
      #expect(text == "hello there")
    case .execute:
      #expect(Bool(false))
    }
  }

  @Test("route returns execute for env-resolved tool")
  func routeExecuteForName() throws {
    let router = CLIAIntentRouter()
    let intent = try router.route("!  echo hi")
    switch intent {
    case .chat:
      #expect(Bool(false))
    case .execute(let spec):
      #expect(spec.executable.ref == .name("echo"))
      #expect(spec.args == ["hi"])
      #expect(spec.hostKind == .env(options: []))
    }
  }

  @Test("route returns execute for path-based tool")
  func routeExecuteForPath() throws {
    let router = CLIAIntentRouter()
    let intent = try router.route("  ! /bin/echo hi")
    switch intent {
    case .chat:
      #expect(Bool(false))
    case .execute(let spec):
      #expect(spec.executable.ref == .path("/bin/echo"))
      #expect(spec.args == ["hi"])
      #expect(spec.hostKind == .direct)
    }
  }

  @Test("route returns chat when only execute prefix is provided")
  func routeChatWhenNoCommand() throws {
    let router = CLIAIntentRouter()
    let intent = try router.route("!   ")
    switch intent {
    case .chat(let text):
      #expect(text == "!   ")
    case .execute:
      #expect(Bool(false))
    }
  }
}
