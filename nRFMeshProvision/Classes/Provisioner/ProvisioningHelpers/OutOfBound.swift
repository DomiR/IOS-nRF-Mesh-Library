//
//  OutOfBand.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 06.03.19.
//

import Foundation

public enum OOBType: UInt8 {
    // - Nothing
    case noOOB = 0x00
    // - enter a 16-bit value provided by the device manufacturer to be entered during hte provisioning process
    case staticOOB = 0x01
    // - enter the number of times the device blinked, beeped, vibrated, displayed or an alphanumeric value displayed by the device
    case outputOOB = 0x02
    // - push, twist, input a number or an alpha numeric value displayed on the provisioner app
    case inputOOB = 0x03
}


public protocol OutOfBoundActionsProtocol {
    func toByteValue() -> UInt8?
    func description() -> String
    var rawValue: UInt16 {get}
}
