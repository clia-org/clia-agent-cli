import Foundation

public enum ExtensionValue: Codable, Sendable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object(Notes)
  case array([ExtensionValue])
  case null

  public init(from decoder: any Decoder) throws {
    let c = try decoder.singleValueContainer()
    if c.decodeNil() {
      self = .null
      return
    }
    if let v = try? c.decode(String.self) {
      self = .string(v)
      return
    }
    if let v = try? c.decode(Bool.self) {
      self = .bool(v)
      return
    }
    if let v = try? c.decode(Double.self) {
      self = .number(v)
      return
    }
    if let v = try? c.decode(Notes.self) {
      self = .object(v)
      return
    }
    if let v = try? c.decode([ExtensionValue].self) {
      self = .array(v)
      return
    }
    throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported extension value")
  }

  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .null: try c.encodeNil()
    case .string(let v): try c.encode(v)
    case .number(let v): try c.encode(v)
    case .bool(let v): try c.encode(v)
    case .object(let v): try c.encode(v)
    case .array(let v): try c.encode(v)
    }
  }
}
