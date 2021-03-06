//
//  ProvisionedMeshNodeDelegate.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import Foundation

public protocol ProvisionedMeshNodeDelegate {
    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode)
    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode)
    func receivedCompositionData(_ compositionData: CompositionStatusMessage)
    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage)
    func receivedRelayConfig(_ modelAppStatusData: ConfigRelayStatusMessage)
    func receivedNetworkTransmitStatus(_ modelAppStatusData: ConfigNetworkTransmitStatusMessage)
    func receivedModelAppStatus(_ modelAppStatusData: ModelAppStatusMessage)
    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage)
    func receivedModelSubsrciptionStatus(_ modelSubscriptionStatusData: ModelSubscriptionStatusMessage)
    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage)
    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage)
    func configurationSucceeded()


    // Generic model
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage)
    func receivedGenericLevelStatusMessage(_ status: GenericLevelStatusMessage)
    func receivedGenericOnPowerUpStatusMessage(_ status: GenericOnPowerUpStatusMessage)
    func receivedLightLightnessStatusMessage(_ status: LightLightnessStatusMessage)
    func receivedLightCtlStatusMessage(_ status: LightCtlStatusMessage)
    func receivedLightHslStatusMessage(_ status: LightHslStatusMessage)
    func receivedLightLightnessDefaultStatusMessage(_ status: LightLightnessDefaultStatusMessage)
    func receivedLightCtlDefaultStatusMessage(_ status: LightCtlDefaultStatusMessage)
    func receivedLightHslDefaultStatusMessage(_ status: LightHslDefaultStatusMessage)
    func receivedGenericUserPropertyStatusMessage(_ status: GenericUserPropertyStatusMessage)
    func receivedHealthAttentionStatusMessage(_ status: HealthAttentionStatusMessage)
    func receivedHealthFaultStatusMessage(_ status: HealthFaultStatusMessage)

    // Scene model
    func receivedSceneStatusMessage(_ status: SceneStatusMessage);
    func receivedSceneRegisterStatusMessage(_ status: SceneRegisterStatusMessage);

    // Vendor model
    func receivedVendorModelStatusMessage(_ status: VendorModelStatusMessage)

    // Sent for unacknowledged messages
    func sentGenericUserPropertySetUnacknowledged(_ destinationAddress: Data)
    func sentGenericOnOffSetUnacknowledged(_ destinationAddress: Data)
    func sentGenericLevelSetUnacknowledged(_ destinationAddress: Data)
    func sentGenericOnPowerUpSetUnacknowledged(_ destinationAddress: Data)

    func sentLightLightnessSetUnacknowledged(_ destinationAddress: Data)
    func sentLightCtlSetUnacknowledged(_ destinationAddress: Data)
    func sentLightHslSetUnacknowledged(_ destinationAddress: Data)

    func sentLightLightnessDefaultSetUnacknowledged(_ destinationAddress: Data)
    func sentLightCtlDefaultSetUnacknowledged(_ destinationAddress: Data)
    func sentLightHslDefaultSetUnacknowledged(_ destinationAddress: Data)

    func sentSceneStoreUnacknowledged(_ destinationAddress: Data)
    func sentSceneDeleteUnacknowledged(_ destinationAddress: Data)
    func sentSceneRecallUnacknowledged(_ destinationAddress: Data)

    func sentVendorModelUnacknowledged(_ destinationAddress: Data)
    func sentHealthAttentionSetUnacknowledged(_ destinationAddress: Data)
}
