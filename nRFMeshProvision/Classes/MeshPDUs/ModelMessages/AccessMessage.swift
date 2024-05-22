import Foundation

public struct AccessMessage {
    public var opcode: Data
    public var payload: Data

    public init(withOpcode aOpcode: Data, andPayload aPayload: Data) {
      opcode = aOpcode;
      payload = aPayload;
    }
}
