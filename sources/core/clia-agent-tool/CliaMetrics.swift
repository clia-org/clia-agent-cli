import Foundation
import Metrics

enum CliaMetrics {
  static func recordInvocation(commandName: String) {
    let counter = Counter(
      label: "clia.invocations",
      dimensions: [
        ("command", commandName)
      ])
    counter.increment()
  }

  static func flush() {
    // Placeholder for metrics backends (Prometheus, etc.)
  }
}
