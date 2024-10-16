//
//  AccessMessageParser.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct AccessMessageParser {

    public static func parseData(_ someData: Data, withOpcode anOpcode: Data, sourceAddress aSourceAddress: Data) -> Any? {
        // handle vendor messages, which are
        switch anOpcode.count {
        case 1:
            switch anOpcode {
            case Data([0x02]):
                return CompositionStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x05]):
                return HealthFaultStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x5E]):
                return SceneStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x4E]):
                return GenericUserPropertyStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x5D]):
                return TimeStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x5F]):
                return SchedulerActionStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x67]):
                return BLOBBlockStatus(withPayload: someData, andSourceAddress: aSourceAddress)
            default:
                return nil
            }

        case 2:
            switch anOpcode {
            case Data([0x80, 0x07]):
                return HealthAttentionStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x03]):
                return AppKeyStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x14]):
                return ConfigProxyStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x25]):
                return ConfigNetworkTransmitStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x28]):
                return ConfigRelayStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x3E]):
                return ModelAppStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x19]):
                return ModelPublicationStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x1F]):
                return ModelSubscriptionStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x0E]):
                return DefaultTTLStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x80, 0x4A]):
                return NodeResetStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)

            //Generic Model Messages
            case Data([0x82, 0x04]):
                return GenericOnOffStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x08]):
                return GenericLevelStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x4E]):
                return LightLightnessStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x60]):
                return LightCtlStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x78]):
                return LightHslStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x56]):
                return LightLightnessDefaultStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x68]):
                return LightCtlDefaultStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x7C]):
                return LightHslDefaultStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x45]):
                return SceneRegisterStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x12]):
                return GenericOnPowerUpStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x3A]):
                return TimeRoleStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x3D]):
                return TimezoneStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x40]):
                return TaiUtcDeltaStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x82, 0x4A]):
                return SchedulerStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress)
            case Data([0x83, 0x03]):
                return BLOBTransferStatus(withPayload: someData, andSourceAddress: aSourceAddress)
            default:
                return nil;
            }

        case 3:
            return VendorModelStatusMessage(withPayload: someData, andSourceAddress: aSourceAddress);

        default:
            return nil;
        }

    }
}
