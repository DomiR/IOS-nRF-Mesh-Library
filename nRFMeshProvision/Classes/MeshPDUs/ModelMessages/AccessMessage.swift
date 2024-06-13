import Foundation

public struct GenericAccessMessage {
    public var pdu: Data;
    public var sourceAddress: Data

    public init(withPdu pdu: Data, andSourceAddress srcAddress: Data) {
      self.pdu = pdu;
      sourceAddress = srcAddress;
    }
}
