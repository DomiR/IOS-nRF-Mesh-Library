//
//  ProvisionedMeshNode.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import UIKit
import CoreBluetooth

public class ProvisionedMeshNode: NSObject, ProvisionedMeshNodeProtocol {

    // MARK: - MeshNode Properties
    public  var logDelegate         : ProvisionedMeshNodeLoggingDelegate?
    public  var delegate            : ProvisionedMeshNodeDelegate?
    private var peripheral          : CBPeripheral
    public var meshNodeIdentifier  : String
    private var proxyDataIn         : CBCharacteristic!
    private var proxyDataOut        : CBCharacteristic!
    private var proxyService        : CBService!
    private var configurationState  : ConfiguratorStateProtocol!
    private var genericControllerState: GenericModelControllerStateProtocol!
    private var stateManager        : MeshStateManager

    // MARK: - MeshNode implementation
    public init(withStateManager aStateManager: MeshStateManager, withUnprovisionedNode aNode: UnprovisionedMeshNode, andDelegate aDelegate: ProvisionedMeshNodeDelegate?) {
        stateManager        = aStateManager
        peripheral          = aNode.basePeripheral()
        delegate            = aDelegate
        meshNodeIdentifier  = aNode.meshNodeIdentifier

        super.init()
    }

    convenience public init(withUnprovisionedNode aNode: UnprovisionedMeshNode, andDelegate aDelegate: ProvisionedMeshNodeDelegate?) {
        self.init(withStateManager: MeshStateManager.restoreState()!, withUnprovisionedNode: aNode, andDelegate: aDelegate)
    }

    convenience public init(withUnprovisionedNode aNode: UnprovisionedMeshNode) {
        self.init(withStateManager: MeshStateManager.restoreState()!, withUnprovisionedNode: aNode, andDelegate: nil)
    }

    public func overrideBLEPeripheral(_ aPeripheral: CBPeripheral) {
        peripheral = aPeripheral
    }

    public func discover() {
        //Destination address is irrelevant here
        configurationState = DiscoveryConfiguratorState(withTargetProxyNode: self, destinationAddress: Data(), andStateManager: stateManager)
        configurationState.execute()
    }

    public func shouldDisconnect() {
        delegate?.nodeShouldDisconnect(self)
    }

    // MARK: ProvisionedMeshNodeDelegate
    // MARK: - ProvisionedMeshNodeProtocol
    func configurationCompleted() {
        delegate?.configurationSucceeded()
    }

    func completedDiscovery(withProxyService aProxyService: CBService, dataInCharacteristic aDataInCharacteristic: CBCharacteristic, andDataOutCharacteristic aDataOutCharacteristic: CBCharacteristic) {
        proxyService = aProxyService
        proxyDataOut = aDataOutCharacteristic
        proxyDataIn  = aDataInCharacteristic
        self.switchToState(SleepConfiguratorState(withTargetProxyNode: self, destinationAddress: Data(), andStateManager: stateManager))
        delegate?.nodeDidCompleteDiscovery(self)
    }

    public func nodeSubscriptionAddressAdd(_ aSubcriptionAddress: Data,
                                           onElementAddress anElementAddress: Data,
                                           modelIdentifier anIdentifier: Data,
                                           onDestinationAddress anAddress: Data) {
        let nodeSubscriptionAddState = ModelSubscriptionAddConfiguratorState(withTargetProxyNode: self,
                                                                          destinationAddress: anAddress,
                                                                          andStateManager: stateManager)
        nodeSubscriptionAddState.setSubscription(elementAddress: anElementAddress,
                                              subscriptionAddress: aSubcriptionAddress,
                                              andModelIdentifier: anIdentifier)

        configurationState = nodeSubscriptionAddState
        configurationState.execute()
    }

    public func nodeSubscriptionAddressDelete(_ aSubcriptionAddress: Data,
                                           onElementAddress anElementAddress: Data,
                                           modelIdentifier anIdentifier: Data,
                                           onDestinationAddress anAddress: Data) {
        let nodeSubscriptionDeleteState = ModelSubscriptionDeleteConfiguratorState(withTargetProxyNode: self,
                                                                          destinationAddress: anAddress,
                                                                          andStateManager: stateManager)
        nodeSubscriptionDeleteState.setSubscription(elementAddress: anElementAddress,
                                              subscriptionAddress: aSubcriptionAddress,
                                              andModelIdentifier: anIdentifier)

        configurationState = nodeSubscriptionDeleteState
        configurationState.execute()
    }

    public func nodeGenericUserPropertyGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withKey aKey: Data) {
        let getState = GenericUserPropertyGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        getState.setUserPropertyKey(aTargetKey: aKey);
        genericControllerState = getState
        genericControllerState.execute()
    }

//    public func nodeGenericOnOffSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
//        let setState = GenericOnOffSetControllerState(withTargetProxyNode: self,
//                                                      destinationAddress: anAddress,
//                                                      andStateManager: stateManager)
//        setState.setTargetState(aTargetState: aState)
//        genericControllerState = setState
//        genericControllerState.execute()
//    }
//
//    public func nodeGenericOnOffSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
//        let setState = GenericOnOffSetControllerState(withTargetProxyNode: self,
//                                                      destinationAddress: anAddress,
//                                                      andStateManager: stateManager)
//        setState.setParametrizedTargetState(aTargetState: aState, withTransitionTime: aTransitionTime, andTransitionDelay: aTransitionDelay)
//        genericControllerState = setState
//        genericControllerState.execute()
//    }
//
//    public func nodeGenericOnOffSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
//        let setState = GenericOnOffSetUnacknowledgedControllerState(withTargetProxyNode: self,
//                                                                    destinationAddress: anAddress,
//                                                                    andStateManager: stateManager)
//        setState.setTargetState(aTargetState: aState)
//        genericControllerState = setState
//        genericControllerState.execute()
//    }

    public func nodeGenericLevelGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getState = GenericLevelGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getState
        genericControllerState.execute()
    }

    public func nodeGenericLevelSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetLevelState aState: Data) {
        let setState = GenericLevelSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setTargetState(aTargetState: aState)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericLevelSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetLevelState aState: Data) {
        let setState = GenericLevelSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setTargetState(aTargetState: aState)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericLevelSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetLevelState aState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        let setState = GenericLevelSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setParametrizedTargetState(aTargetState: aState, withTransitionTime: aTransitionTime, andTransitionDelay: aTransitionDelay)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericMoveSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withDeltaLevelState aState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        let setState = GenericMoveSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setParametrizedTargetState(aTargetState: aState, withTransitionTime: aTransitionTime, andTransitionDelay: aTransitionDelay)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericOnPowerUpGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
           let getState = GenericOnPowerUpGetControllerState(withTargetProxyNode: self,
                                                         destinationAddress: anAddress,
                                                         andStateManager: stateManager)
           genericControllerState = getState
           genericControllerState.execute()
       }

       public func nodeGenericOnPowerUpSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withTargetState aState: Data) {
           let setState = GenericOnPowerUpSetControllerState(withTargetProxyNode: self,
                                                         destinationAddress: anAddress,
                                                         andStateManager: stateManager)
           setState.setTargetState(aTargetState: aState)
           genericControllerState = setState
           genericControllerState.execute()
       }

       public func nodeGenericOnPowerUpSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withTargetState aState: Data) {
           let setState = GenericOnPowerUpSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                         destinationAddress: anAddress,
                                                         andStateManager: stateManager)
           setState.setTargetState(aTargetState: aState)
           genericControllerState = setState
           genericControllerState.execute()
       }

    public func nodeGenericOnOffSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        let setState = GenericOnOffSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setParametrizedTargetState(aTargetState: aState, withTransitionTime: aTransitionTime, andTransitionDelay: aTransitionDelay)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericOnOffSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setState = GenericOnOffSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setTargetState(aTargetState: aState)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericOnOffSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data, transitionTime aTransitionTime: Data, andTransitionDelay aTransitionDelay: Data) {
        let setState = GenericOnOffSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setParametrizedTargetState(aTargetState: aState, withTransitionTime: aTransitionTime, andTransitionDelay: aTransitionDelay)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericOnOffSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setState = GenericOnOffSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setTargetState(aTargetState: aState)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericOnOffGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getState = GenericOnOffGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getState
        genericControllerState.execute()
    }

    public func nodeHealthAttentionGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getState = HealthAttentionGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getState
        genericControllerState.execute()
    }

    public func nodeHealthFaultGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withCompanyId aCompanyId: Data) {
        let getState = HealthFaultGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        getState.setTargetState(aTargetState: aCompanyId);
        genericControllerState = getState
        genericControllerState.execute()
    }

    public func nodeHealthFaultTest(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withTestId testId: Data, withCompanyId aCompanyId: Data) {
           let state = HealthFaultTestControllerState(withTargetProxyNode: self,
                                                         destinationAddress: anAddress,
                                                         andStateManager: stateManager)
           state.setTestId(aTestId: testId)
        state.setCompanyId(aCompanyId: aCompanyId);
           genericControllerState = state
           genericControllerState.execute()
       }

    public func nodeHealthAttentionSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setHealthAttentionState = HealthAttentionSetControllerState(withTargetProxyNode: self,
                                                                      destinationAddress: anAddress,
                                                                      andStateManager: stateManager)
        setHealthAttentionState.setTargetState(aTargetState: aState);
        genericControllerState = setHealthAttentionState
        genericControllerState.execute()
    }

    public func nodeHealthAttentionSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setHealthAttentionState = HealthAttentionSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                                    destinationAddress: anAddress,
                                                                                    andStateManager: stateManager)
        setHealthAttentionState.setTargetState(aTargetState: aState);
        genericControllerState = setHealthAttentionState
        genericControllerState.execute()
    }


    public func nodeLightLightnessGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getLightLightnessState = LightLightnessGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getLightLightnessState
        genericControllerState.execute()
    }

    public func nodeLightLightnessSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightLightnessState = LightLightnessSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setLightLightnessState.setTargetState(aTargetState: aState);
        genericControllerState = setLightLightnessState
        genericControllerState.execute()
    }

    public func nodeLightLightnessSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightLightnessState = LightLightnessSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                      destinationAddress: anAddress,
                                                                      andStateManager: stateManager)
        setLightLightnessState.setTargetState(aTargetState: aState);
        genericControllerState = setLightLightnessState
        genericControllerState.execute()
    }

     public func nodeLightLightnessDefaultGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getLightLightnessDefaultState = LightLightnessDefaultGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getLightLightnessDefaultState
        genericControllerState.execute()
    }

    public func nodeLightLightnessDefaultSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightLightnessDefaultState = LightLightnessDefaultSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setLightLightnessDefaultState.setTargetState(aTargetState: aState);
        genericControllerState = setLightLightnessDefaultState
        genericControllerState.execute()
    }

    public func nodeLightLightnessDefaultSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightLightnessDefaultState = LightLightnessDefaultSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                      destinationAddress: anAddress,
                                                                      andStateManager: stateManager)
        setLightLightnessDefaultState.setTargetState(aTargetState: aState);
        genericControllerState = setLightLightnessDefaultState
        genericControllerState.execute()
    }

    public func nodeLightCtlGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getState = LightCtlGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getState
        genericControllerState.execute()
    }

    public func nodeLightCtlSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightLightnessState = LightCtlSetControllerState(withTargetProxyNode: self,
                                                                      destinationAddress: anAddress,
                                                                      andStateManager: stateManager)
        setLightLightnessState.setTargetState(aTargetState: aState);
        genericControllerState = setLightLightnessState
        genericControllerState.execute()
    }

    public func nodeLightCtlSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightCtlUnacknowledgedState = LightCtlSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                destinationAddress: anAddress,
                                                                andStateManager: stateManager)
        setLightCtlUnacknowledgedState.setTargetState(aTargetState: aState);
        genericControllerState = setLightCtlUnacknowledgedState
        genericControllerState.execute()
    }

     public func nodeLightCtlDefaultGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getState = LightCtlDefaultGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = getState
        genericControllerState.execute()
    }

    public func nodeLightCtlDefaultSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightLightnessState = LightCtlDefaultSetControllerState(withTargetProxyNode: self,
                                                                      destinationAddress: anAddress,
                                                                      andStateManager: stateManager)
        setLightLightnessState.setTargetState(aTargetState: aState);
        genericControllerState = setLightLightnessState
        genericControllerState.execute()
    }

    public func nodeLightCtlDefaultSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightCtlDefaultUnacknowledgedState = LightCtlDefaultSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                destinationAddress: anAddress,
                                                                andStateManager: stateManager)
        setLightCtlDefaultUnacknowledgedState.setTargetState(aTargetState: aState);
        genericControllerState = setLightCtlDefaultUnacknowledgedState
        genericControllerState.execute()
    }

    public func nodeLightHslGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = LightHslGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeLightHslSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let state = LightHslSetControllerState(withTargetProxyNode: self,
                                                                              destinationAddress: anAddress,
                                                                              andStateManager: stateManager)
        state.setTargetState(aTargetState: aState);
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeLightHslSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightHslUnacknowledgedState = LightHslSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                                      destinationAddress: anAddress,
                                                                                      andStateManager: stateManager)
        setLightHslUnacknowledgedState.setTargetState(aTargetState: aState);
        genericControllerState = setLightHslUnacknowledgedState
        genericControllerState.execute()
    }

      public func nodeLightHslDefaultGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = LightHslDefaultGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeLightHslDefaultSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let state = LightHslDefaultSetControllerState(withTargetProxyNode: self,
                                                                              destinationAddress: anAddress,
                                                                              andStateManager: stateManager)
        state.setTargetState(aTargetState: aState);
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeLightHslDefaultSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setLightHslDefaultUnacknowledgedState = LightHslDefaultSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                                                      destinationAddress: anAddress,
                                                                                      andStateManager: stateManager)
        setLightHslDefaultUnacknowledgedState.setTargetState(aTargetState: aState);
        genericControllerState = setLightHslDefaultUnacknowledgedState
        genericControllerState.execute()
    }

    public func nodeTimeGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = TimeGetControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeTimeSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withPayload aPayload: Data) {
      let state = TimeSetControllerState(withTargetProxyNode: self,
                                                    destinationAddress: anAddress,
                                                    andStateManager: stateManager)
      state.setTargetState(aPayload: aPayload);
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeTimeRoleGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = TimeRoleGetControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeTimeRoleSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withPayload aPayload: Data) {
      let state = TimeRoleSetControllerState(withTargetProxyNode: self,
                                         destinationAddress: anAddress,
                                         andStateManager: stateManager)
      state.setTargetState(aPayload: aPayload);
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeTimezoneGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = TimezoneGetControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeTimezoneSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withPayload aPayload: Data) {
      let state = TimezoneSetControllerState(withTargetProxyNode: self,
                                             destinationAddress: anAddress,
                                             andStateManager: stateManager)
      state.setTargetState(aPayload: aPayload);
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeTaiUtcDeltaGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
      let state = TaiUtcDeltaGetControllerState(withTargetProxyNode: self,
                                             destinationAddress: anAddress,
                                             andStateManager: stateManager)
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeTaiUtcDeltaSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withPayload aPayload: Data) {
      let state = TaiUtcDeltaSetControllerState(withTargetProxyNode: self,
                                             destinationAddress: anAddress,
                                             andStateManager: stateManager)
      state.setTargetState(aPayload: aPayload);
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeSchedulerGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
      let state = SchedulerGetControllerState(withTargetProxyNode: self,
                                                destinationAddress: anAddress,
                                                andStateManager: stateManager)
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeSchedulerActionGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withIndex aIndex: Data) {
      let state = SchedulerActionGetControllerState(withTargetProxyNode: self,
                                              destinationAddress: anAddress,
                                              andStateManager: stateManager)

      state.setIndex(aIndex: aIndex)
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeSchedulerActionSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withPayload aPayload: Data) {
      let state = SchedulerActionSetControllerState(withTargetProxyNode: self,
                                                destinationAddress: anAddress,
                                                andStateManager: stateManager)
      state.setTargetState(aPayload: aPayload);
      genericControllerState = state
      genericControllerState.execute()
    }

    public func nodeSchedulerActionSetUnacknowledged(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withPayload aPayload: Data) {
      let state = SchedulerActionSetUnacknowledgedControllerState(withTargetProxyNode: self,
                                                    destinationAddress: anAddress,
                                                    andStateManager: stateManager)
      state.setTargetState(aTargetState: aPayload);
      genericControllerState = state
      genericControllerState.execute()
    }



    public func nodeSceneGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = SceneGetControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneStore(_ anOpcode: Data,
                                   withSceneNumber sceneNumber: Data,
                                   onDestinationAddress anAddress: Data) {
        let state = SceneStoreControllerState(withTargetProxyNode: self,
                                                            destinationAddress: anAddress,
                                                            andStateManager: stateManager)
        state.setSceneNumber(withSceneNumber: sceneNumber);
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneStoreUnacknowledged(_ anOpcode: Data,
                               withSceneNumber sceneNumber: Data,
                               onDestinationAddress anAddress: Data) {
        let state = SceneStoreUnacknowledgedControllerState(withTargetProxyNode: self,
                                              destinationAddress: anAddress,
                                              andStateManager: stateManager)
        state.setSceneNumber(withSceneNumber: sceneNumber);
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneDelete(_ anOpcode: Data,
                               withSceneNumber sceneNumber: Data,
                               onDestinationAddress anAddress: Data) {
        let state = SceneDeleteControllerState(withTargetProxyNode: self,
                                              destinationAddress: anAddress,
                                              andStateManager: stateManager)
        state.setSceneNumber(withSceneNumber: sceneNumber);
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneDeleteUnacknowledged(_ anOpcode: Data,
                                withSceneNumber sceneNumber: Data,
                                onDestinationAddress anAddress: Data) {
        let state = SceneDeleteUnacknowledgedControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        state.setSceneNumber(withSceneNumber: sceneNumber);
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneRegisterGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let state = SceneRegisterGetControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneRecall(_ anElementAddress: Data, withSceneNumber sceneNumber: Data, onDestinationAddress anAddress: Data) {
        let state = SceneRecallControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        state.setSceneNumber(withSceneNumber: sceneNumber)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func nodeSceneRecallUnacknowledged(_ anElementAddress: Data, withSceneNumber sceneNumber: Data, onDestinationAddress anAddress: Data) {
        let state = SceneRecallUnacknowledgedControllerState(withTargetProxyNode: self,
                                               destinationAddress: anAddress,
                                               andStateManager: stateManager)
        state.setSceneNumber(withSceneNumber: sceneNumber)
        genericControllerState = state
        genericControllerState.execute()
    }

    public func blobTransferStart(_ anElementAddress: Data, withSceneNumber sceneNumber: Data, onDestinationAddress anAddress: Data) {
        let blobTransferState = BlobTransferStartConfiguratorState(withTargetProxyNode: self,
                                                                   destinationAddress: anAddress,
                                                                   andStateManager: stateManager)
        blobTransferState.setBlobData(aData)
        genericControllerState = blobTransferState
        genericControllerState.execute()
    }

    public func blobBlockStart(_ anElementAddress: Data, withSceneNumber sceneNumber: Data, onDestinationAddress anAddress: Data) {
        let blobTransferState = BlobBlockStartConfiguratorState(withTargetProxyNode: self,
                                                                   destinationAddress: anAddress,
                                                                   andStateManager: stateManager)
        blobTransferState.setBlobData(aData)
        genericControllerState = blobTransferState
        genericControllerState.execute()
    }

    public func blobChunkTransfer(_ anElementAddress: Data, withSceneNumber sceneNumber: Data, onDestinationAddress anAddress: Data) {
        let blobTransferState = BlobChunkTransferConfiguratorState(withTargetProxyNode: self,
                                                                   destinationAddress: anAddress,
                                                                   andStateManager: stateManager)
        blobTransferState.setBlobData(aData)
        genericControllerState = blobTransferState
        genericControllerState.execute()
    }

    public func vendorModelMessage(_ anOpcode: Data,
                                   withPayload aParams: Data,
                                   onDestinationAddress anAddress: Data) {
        let vendorState = VendorModelMessageControllerState(withTargetProxyNode: self,
                                                            destinationAddress: anAddress,
                                                            andStateManager: stateManager)
        //vendorState.setBinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        vendorState.setOpcode(aOpcode: anOpcode)
        vendorState.setParams(aParams: aParams)
        genericControllerState = vendorState
        genericControllerState.execute()
    }

    public func vendorModelUnacknowledgedMessage(_ anOpcode: Data,
                                   withPayload aParams: Data,
                                   onDestinationAddress anAddress: Data) {
        let vendorState = VendorModelUnacknowledgedMessageControllerState(withTargetProxyNode: self,
                                                            destinationAddress: anAddress,
                                                            andStateManager: stateManager)
        //vendorState.setBinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        vendorState.setOpcode(aOpcode: anOpcode)
        vendorState.setParams(aParams: aParams)
        genericControllerState = vendorState
        genericControllerState.execute()
    }


    public func nodePublicationAddressSet(_ aPublicationAddress: Data,
                                  onElementAddress anElementAddress: Data,
                                  appKeyIndex anAppKeyIndex: Data,
                                  credentialFlag aCredentialFlag: Bool,
                                  ttl aTTL: Data,
                                  period aPeriod: Data,
                                  retransmitCount aCount: Data,
                                  retransmitInterval anInterval: Data,
                                  modelIdentifier anIdentifier: Data,
                                  onDestinationAddress anAddress: Data) {
        let nodePublishAddressState = ModelPublicationSetConfiguratorState(withTargetProxyNode: self,
                                                                           destinationAddress: anAddress,
                                                                           andStateManager: stateManager)
        nodePublishAddressState.setPublish(elementAddress: anElementAddress,
                                           appKeyIndex: anAppKeyIndex,
                                           credentialFlag: aCredentialFlag,
                                           publishAddress: aPublicationAddress,
                                           publishTTL: aTTL,
                                           publishPeriod: aPeriod,
                                           retransmitCount: aCount,
                                           retransmitInterval: anInterval,
                                           andModelIdentifier: anIdentifier)
        configurationState = nodePublishAddressState
        configurationState.execute()
    }

    public func appKeyDelete(atIndex anAppKeyIndex: Data,
                             forNetKeyAtIndex aNetKeyIndex: Data,
                             onDestinationAddress anAddress: Data) {
        let deleteKeyState = AppKeyDeleteConfiguratorState(withTargetProxyNode: self,
                                                     destinationAddress: anAddress,
                                                     andStateManager: stateManager)
        deleteKeyState.setAppKeyIndex(anAppKeyIndex, andNetKeyIndex: aNetKeyIndex)
        configurationState = deleteKeyState
        configurationState.execute()
    }

    public func appKeyAdd(_ anAppKey: Data,
                          atIndex anIndex: Data,
                          forNetKeyAtIndex aNetKeyIndex: Data,
                          onDestinationAddress anAddress: Data) {
        let addKeyState = AppKeyAddConfiguratorState(withTargetProxyNode: self,
                                                     destinationAddress: anAddress,
                                                     andStateManager: stateManager)
        addKeyState.setAppKey(withData: anAppKey, appKeyIndex: anIndex, netKeyIndex: aNetKeyIndex)
        configurationState = addKeyState
        configurationState.execute()
    }

    public func bindAppKey(withIndex anAppKeyIndex: Data,
                           modelId aModelId: Data,
                           elementAddress anElementAddress: Data,
                           onDestinationAddress anAddress: Data) {
        let bindState = ModelAppBindConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        bindState.setBinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        configurationState = bindState
        configurationState.execute()
    }

    public func getConfigRelay(destinationAddress: Data) {
        let state = ConfigRelayGetConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: destinationAddress,
                                                      andStateManager: stateManager)
        configurationState = state
        configurationState.execute()
    }

    public func setConfigProxy(destinationAddress: Data,
                               withProxy proxy: Int) {
        let state = ConfigProxySetConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: destinationAddress,
                                                      andStateManager: stateManager)
        state.setProxy(withProxy: proxy)
        configurationState = state
        configurationState.execute()
    }

    public func setConfigRelay(destinationAddress: Data,
                               withRelay relay: Int,
                               withRelayRetransmitCount relayRetransmitCount: Int,
                               withRelayRetransmitIntervalSteps relayRetransmitIntervalSteps: Int) {
        let state = ConfigRelaySetConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: destinationAddress,
                                                      andStateManager: stateManager)
        state.setRelay(withRelay: relay, withRelayRetransmitCount: relayRetransmitCount, withRelayRetransmitIntervalSteps: relayRetransmitIntervalSteps)
        configurationState = state
        configurationState.execute()
    }

    public func getConfigNetworkTransmit(destinationAddress: Data) {
        let state = ConfigNetworkTransmitGetConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: destinationAddress,
                                                      andStateManager: stateManager)
        configurationState = state
        configurationState.execute()
    }

    public func setConfigNetworkTransmit(destinationAddress: Data,
                              withNetworkTransmitCount networkTransmitCount: Int,
                              withNetworkTransmitIntervalSteps networkTransmitIntervalSteps: Int) {
        let state = ConfigNetworkTransmitSetConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: destinationAddress,
                                                      andStateManager: stateManager)
        state.setNetworkTransmit(withNetworkTransmitCount: networkTransmitCount, withNetworkTransmitIntervalSteps: networkTransmitIntervalSteps)
        configurationState = state
        configurationState.execute()
    }

    public func unbindAppKey(withIndex anAppKeyIndex: Data,
                             modelId aModelId: Data,
                             elementAddress anElementAddress: Data,
                             onDestinationAddress anAddress: Data) {
        let unbindState = ModelAppUnbindConfiguratorState(withTargetProxyNode: self,
                                                        destinationAddress: anAddress,
                                                        andStateManager: stateManager)
        unbindState.setUnbinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        configurationState = unbindState
        configurationState.execute()
    }

    public func resetNode(destinationAddress: Data) {
        configurationState = NodeResetConfiguratorState(withTargetProxyNode: self, destinationAddress: destinationAddress, andStateManager: stateManager)
        configurationState.execute()
    }

    public func configure(destinationAddress: Data) {
        //First step of configuration is to get composition
        configurationState = CompositionGetConfiguratorState(withTargetProxyNode: self, destinationAddress: destinationAddress, andStateManager: stateManager)
        configurationState.execute()

    }

    func switchToState(_ nextState: ConfiguratorStateProtocol) {
        print("Switching state to \(nextState.humanReadableName())")
        configurationState = nextState
        configurationState.execute()
    }

    func basePeripheral() -> CBPeripheral {
        return peripheral
    }

    func discoveredServicesAndCharacteristics() -> (proxyService: CBService?, dataInCharacteristic: CBCharacteristic?, dataOutCharacteristic: CBCharacteristic?) {
        return (proxyService, proxyDataIn, proxyDataOut)
    }

    // MARK: - Accessors
    public func blePeripheral() -> CBPeripheral {
        return peripheral
    }

    public func nodeBLEName() -> String {
        return peripheral.name ?? "N/A"
    }

    // MARK: - NSObject Protocols
    override public func isEqual(_ object: Any?) -> Bool {
        if let aNode = object as? ProvisionedMeshNode {
            return aNode.blePeripheral().identifier == blePeripheral().identifier
        } else {
            return false
        }
   }
}
