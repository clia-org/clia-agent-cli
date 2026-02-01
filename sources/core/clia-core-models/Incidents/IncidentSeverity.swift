import Foundation

public enum IncidentSeverity: Codable, Sendable, Equatable {
  case s0
  case s1
  case s2
  case s3
  case other(String)

  public init(from decoder: any Decoder) throws {
    let c = try decoder.singleValueContainer()
    let raw = (try? c.decode(String.self)) ?? ""
    switch raw.uppercased() {
    case "S0": self = .s0
    case "S1": self = .s1
    case "S2": self = .s2
    case "S3": self = .s3
    default: self = .other(raw)
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .s0: try c.encode("S0")
    case .s1: try c.encode("S1")
    case .s2: try c.encode("S2")
    case .s3: try c.encode("S3")
    case .other(let v): try c.encode(v)
    }
  }

  public var string: String {
    switch self {
    case .s0: return "S0"
    case .s1: return "S1"
    case .s2: return "S2"
    case .s3: return "S3"
    case .other(let v): return v
    }
  }
}
