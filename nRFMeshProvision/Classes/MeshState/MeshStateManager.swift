//
//  MeshStateManager.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshStateManager: NSObject {

    public private (set) var meshState: MeshState!

    private override init() {
        super.init()
    }

    public init(withState aState: MeshState) {
        meshState = aState
    }

    public func state() -> MeshState {
        //restoreState()
        return meshState
    }

    public func saveState() {
        let encodedData = try? JSONEncoder().encode(self.meshState)
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                try encodedData!.write(to: fileURL)
            } catch {
                print(error)
            }
        }
    }

    public func restoreState() {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            do {
                let data = try Data(contentsOf: fileURL)
                let decodedState = try JSONDecoder().decode(MeshState.self, from: data)
                self.meshState = decodedState
            } catch {
                print("Error reading state from file")
                let _ = self.generateState();
            }
        }
    }

    public func generateState() -> Bool {

        let networkKey = generateRandomKey()

        guard networkKey != nil else {
            print("Failed to generate network key")
            return false
        }

        let netKey = NetworkKeyEntry(withName: "Main NetKey", andKey: networkKey!, oldKey: nil, atIndex: Data([0x00, 0x00]), phase: Data([0x00, 0x00, 0x00, 0x00]), andMinSecurity: .high)
        let unicastAddress = Data([0x7F, 0xFF])
        let globalTTL: UInt8 = 5
        let networkName = "My Network"

        let appKeys: [AppKeyEntry] = [
            AppKeyEntry(withName: "AppKey 1", andKey: generateRandomKey()!, atIndex: 0),
            AppKeyEntry(withName: "AppKey 2", andKey: generateRandomKey()!, atIndex: 1),
            AppKeyEntry(withName: "AppKey 3", andKey: generateRandomKey()!, atIndex: 2)
        ]

        let provisioner = MeshProvisionerEntry(withName: "nRF Mesh Provisioner", uuid: UUID(), andUnicastRange: AllocatedUnicastRange(withLowAddress: "0000", andHighAddress: "7F7E"))
        let newState = MeshState(withName: networkName, version: "1.0", identifier: UUID(), timestamp: Date(), provisionerList: [provisioner], nodeList: [], netKeys: [netKey], globalTTL: globalTTL, unicastAddress: unicastAddress, andAppKeys: appKeys)
        self.meshState = newState

        return true

    }

    public func deleteState() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            let fileURL = URL(fileURLWithPath: filePath)
            if FileManager.default.isDeletableFile(atPath: filePath) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    return true
                } catch {
                    print(error.localizedDescription)
                    return false
                }
            }
        }
        return false;

    }

    // MARK: - Static accessors
    public static func restoreState() -> MeshStateManager? {
        if MeshStateManager.stateExists() {
            let aStateManager = MeshStateManager()
            aStateManager.restoreState()
            return aStateManager
        } else {
            return nil
        }
    }

    public static func stateExists() -> Bool {
        if let documentsPath = MeshStateManager.getDocumentDirectory() {
            let filePath = documentsPath.appending("/meshState.bin")
            return FileManager.default.fileExists(atPath: filePath)
        } else {
            return false
        }
    }

    public static func generateState() -> MeshStateManager? {
        let aStateManager = MeshStateManager()
        if aStateManager.generateState() {
            aStateManager.saveState()
        } else {
            print("Failed to create MeshStateManager object")
            return nil
        }
        return aStateManager
    }
    private static func getDocumentDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }

    // MARK: - Generation helper
    private func generateRandomKey() -> Data? {
        return OpenSSLHelper().generateRandom()
    }
}
