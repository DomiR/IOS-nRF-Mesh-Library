import Foundation

public struct GenericAccessMessage {
    public var opcode: Data
    public var payload: Data
    public var sourceAddress: Data

    public init(withOpcode aOpcode: Data, andPayload aPayload: Data, andSourceAddress srcAddress: Data) {
      opcode = aOpcode;
      payload = aPayload;
      sourceAddress = srcAddress;
    }
}
