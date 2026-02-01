import ConsoleKit
import ConsoleKitTerminal
import Foundation

final class InlineActivityIndicator {
  enum State {
    case stopped
    case running
  }

  private var state: State = .stopped
  private var index: Int = 0
  private var style: () -> (Style)
  //  private var sequence: [String]
  private let delay: TimeInterval
  private let outputStrategy: OutputStrategy
  private let activityBar: ActivityIndicator<LoadingBar>?
  private let console: Console
  private var timer: Timer?
  private var currentSequence: [String] = []

  init(
    console: Console = Terminal(),
    style: @escaping () -> (Style) = { Style.random },
    delay: TimeInterval = 0.25,
    outputStrategy: OutputStrategy = XcodeInlineOutputStrategy(),
  ) {
    self.style = style
    self.delay = delay
    self.outputStrategy = outputStrategy
    self.console = console
    activityBar =
      !ProcessInfo.inXcodeEnvironment ? console.loadingBar(title: "Loading") : nil
  }

  func start() {
    guard state == .stopped else {
      return
    }
    state = .running
    timer?.invalidate()
    timer = nil
    if let activityBar {
      activityBar.start()
    } else {
      currentSequence = style().sequence
      let timer = Timer(
        timeInterval: delay,
        target: self,
        selector: #selector(tick(_:)),
        userInfo: nil,
        repeats: true
      )
      self.timer = timer
      RunLoop.main.add(timer, forMode: .common)
    }
  }

  func succeed() {
    guard state == .running else {
      return
    }
    timer?.invalidate()
    timer = nil
    activityBar?.succeed()
    state = .stopped
    outputStrategy.complete()
  }

  @objc
  private func tick(_ timer: Timer) {
    guard state == .running else { return }
    guard !currentSequence.isEmpty else { return }
    outputStrategy.output(currentSequence[index])
    index = (index + 1) % currentSequence.count
  }
}

// Define a protocol for output strategies
protocol OutputStrategy {
  func output(_ string: String)
  func complete()
}

// Output strategy for Xcode
struct XcodeInlineOutputStrategy: OutputStrategy {
  func output(_ string: String) {
    print(string, terminator: "")
    fflush(stdout)
  }

  func complete() {
    print("\n")
  }
}
