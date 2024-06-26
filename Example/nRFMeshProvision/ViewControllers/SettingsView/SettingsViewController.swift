//
//  SettingsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 06/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class SettingsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, ToggleSettingsCellDelegate {

    // MARK: - Properties
    var meshManager: NRFMeshManager!
    let reuseIdentifier = "SettingsTableViewCell"
    let toggleReuseIdentifier = "SettingsTableViewToggleCell"
    let sectionTitles = ["Global Settings", "Network Settings", "App keys", "Mesh State", "About"]
    let rowTitles   = [["Network Name", "Global TTL", "Provisioner Unicast", "Auto rejoin"],
                       ["Network Key", "Key Index", "Flags", "IV Index"],
                       ["Manage App Keys"],
                       ["Reset Mesh State"],
                       ["Application Version", "Build Number"]]

    // MARK: - Outlets and actions
    @IBOutlet weak var settingsTable: UITableView!

    // MARK: - Implementaiton
    private func updateProvisioningDataUI() {
        //Update provisioning Data UI with default values, this is called after modifications are done
        //so we need to save it, and then load it again
        meshManager.stateManager().saveState()
        meshManager.stateManager().restoreState()
        settingsTable.reloadData()
    }

    func didSelectNetworkNameCell() {
        let meshState = meshManager.stateManager().state()
        presentInputViewWithTitle("Enter a network name", message: "20 charcters",
                                  placeholder: meshState.meshName,
                                  generationEnabled: false) { (aName) -> Void in
                                    if let aName = aName {
                                        if aName.count <= 20 {
                                            meshState.meshName = aName
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("Name must shorter than 20 characters")
                                        }
                                    }
        }
    }

    func didSelectGlobalTTLCell() {
        let meshState = meshManager.stateManager().state()
        presentInputViewWithTitle("Enter a TTL value", message: "1 Byte",
                                  placeholder: meshState.globalTTL.hexString(),
                                  generationEnabled: false) { (aTTL) -> Void in
                                    if var aTTL = aTTL {
                                        aTTL = aTTL.lowercased().replacingOccurrences(of: "0x", with: "")
                                        if aTTL.count == 2 {
                                            meshState.globalTTL = Data(hexString: aTTL)!
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("TTL must 1 byte")
                                        }
                                    }
        }
   }

    func didSelectAppKeysCell() {
        performSegue(withIdentifier: "showKeyManagerView", sender: nil)
    }

    func didSelectMeshResetCell() {
        self.presentConfirmationViewWithTitle("Resetting Mesh", message: "Warning: This action is not reversible and will remove all configuration on this provisioner, continue?") { (confirm) in
            if confirm == true {
                if self.meshManager.stateManager().deleteState() {
                    if self.meshManager.stateManager().generateState() {
                        self.settingsTable.reloadData()
                    } else {
                        print("Failed to generate state")
                    }
                } else {
                    print("failed to delete mesh information")
                }
            }
        }
    }
    
    func didSelectKeyCell() {
        let meshState = meshManager.stateManager().state()
        presentInputViewWithTitle("Please enter a Key",
                                  message: "16 Bytes",
                                  placeholder: meshState.netKeys[0].key.hexString(),
                                  generationEnabled: true) { (aKey) -> Void in
                                    if var aKey = aKey {
                                        aKey = aKey.lowercased().replacingOccurrences(of: "0x", with: "")
                                        if aKey.count == 32 {
                                            meshState.netKeys[0].key = Data(hexString: aKey)!
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("Key must be exactly 16 bytes")
                                        }
                                    }
        }
   }

    func didSelectKeyIndexCell() {
        let meshState = meshManager.stateManager().state()
        presentInputViewWithTitle("Please enter a Key Index",
                                  message: "2 Bytes",
                                  placeholder: meshState.netKeys[0].index.hexString(),
                                  generationEnabled: false) { (aKeyIndex) -> Void in
            if var aKeyIndex = aKeyIndex {
                aKeyIndex = aKeyIndex.lowercased().replacingOccurrences(of: "0x", with: "")
                if aKeyIndex.count == 4 {
                    meshState.netKeys[0].index = Data(hexString: aKeyIndex)!
                    print("New Key index = \(meshState.netKeys[0].index.hexString())")
                    self.updateProvisioningDataUI()
                } else {
                    print("Key index must be exactly 2 bytes")
                }
       }
    }
   }

    func generateNewKey() -> Data {
        let helper = OpenSSLHelper()
        let newKey = helper.generateRandom()
        return newKey!
    }

    func didSelectFlagsCell() {
        let meshState = meshManager.stateManager().state()
        let flagsCell = settingsTable.cellForRow(at: IndexPath(item: 2, section: 1))
        let flagSettingsView = storyboard?.instantiateViewController(withIdentifier: "flagsSettingsPopoverView") as? FlagSettingsPopoverViewController
        flagSettingsView?.modalPresentationStyle = .popover
        flagSettingsView?.preferredContentSize = CGSize(width: 300, height: 300)
        let flagPresentationController = flagSettingsView?.popoverPresentationController
        flagPresentationController?.sourceView = flagsCell!.contentView
        flagPresentationController?.sourceRect = flagsCell!.contentView.frame
        flagPresentationController?.delegate = self
        present(flagSettingsView!, animated: true, completion: nil)
        flagSettingsView?.setFlagData(meshState.netKeys[0].flags, andCompletionHandler: { (newFlags) -> (Void) in
            self.deselectSelectedRow()
            if let newFlags = newFlags {
                meshState.netKeys[0].flags = newFlags
                self.updateProvisioningDataUI()
            }
        })
   }

    func didSelectIVIndexCell() {
        let meshState = meshManager.stateManager().state()
        presentInputViewWithTitle("Please enter IV Index",
                                  message: "4 Bytes",
                                  placeholder: meshState.netKeys[0].phase.hexString(),
                                  generationEnabled: false) { (anIVIndex) -> Void in
                                    if var anIVIndex = anIVIndex {
                                        anIVIndex = anIVIndex.lowercased().replacingOccurrences(of: "0x", with: "")
                                        if anIVIndex.count == 8 {
                                            meshState.netKeys[0].phase = Data(hexString: anIVIndex)!
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("IV Index must be exactly 4 bytes")
                                        }
                                    }
        }
   }

    func didSelectUnicastAddressCell() {
        let meshState = meshManager.stateManager().state()
        presentInputViewWithTitle("Please enter Unicast Address",
                                  message: "2 Bytes, >= 0x0001",
                                  placeholder: meshState.unicastAddress.hexString(),
                                  generationEnabled: false) { (anAddress) -> Void in
                                    if var anAddress = anAddress {
                                        anAddress = anAddress.lowercased().replacingOccurrences(of: "0x", with: "")
                                        if anAddress.count == 4 {
                                            if anAddress == "0000" {
                                                print("Adderss cannot be 0x0000 `unassigned`, next possible address is 0x0001")
                                            } else {
                                                meshState.unicastAddress = Data(hexString: anAddress)!
                                                self.updateProvisioningDataUI()
                                            }
                                        } else {
                                            print("Unicast address must be exactly 2 bytes")
                                        }
                                    }
        }
   }

    // MARK: - Alert helpers
    // Input Alert
    func presentInputViewWithTitle(_ aTitle: String,
                                   message aMessage: String, placeholder aPlaceholder: String?,
                                   generationEnabled generationFlag: Bool,
                                   andCompletionHandler aHandler : @escaping (String?) -> Void) {
        let inputAlertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            aTextField.keyboardType = UIKeyboardType.asciiCapable
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            //Show clear button button when user is not editing
            aTextField.clearButtonMode = UITextFieldViewMode.whileEditing
            if let aPlaceholder = aPlaceholder {
                aTextField.text = aPlaceholder
            }
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            DispatchQueue.main.async {
                if let text = inputAlertView.textFields![0].text {
                    if text.count > 0 {
                        if let selectedIndexPath = self.settingsTable.indexPathForSelectedRow {
                            self.deselectSelectedRow()
                            if selectedIndexPath.row == 0 && selectedIndexPath.section == 0 {
                                aHandler(text)
                            } else {
                                aHandler(text.uppercased())
                            }
                   } else {
                            aHandler(text.uppercased())
                        }
                    }
                }
            }
        }

        var generateAction: UIAlertAction!
        if generationFlag {
            generateAction = UIAlertAction(title: "Generate new key", style: .default) { (_) in
                DispatchQueue.main.async {
                    let newKey = self.generateNewKey()
                    self.deselectSelectedRow()
                    aHandler(newKey.hexString())
                }
            }
        }

        let cancelACtion = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                self.deselectSelectedRow()
                aHandler(nil)
            }
        }

        inputAlertView.addAction(saveAction)

        if generationFlag {
            inputAlertView.addAction(generateAction)
        }

        inputAlertView.addAction(cancelACtion)
        present(inputAlertView, animated: true, completion: nil)
    }

    // Confirmation Alert
    func presentConfirmationViewWithTitle(_ aTitle: String,
                                   message aMessage: String,
                                   andCompletionHandler aHandler : @escaping (Bool) -> Void) {
        let confirmationAlertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (_) in
            DispatchQueue.main.async {
                self.deselectSelectedRow()
                aHandler(true)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                self.deselectSelectedRow()
                aHandler(false)
            }
        }

        confirmationAlertView.addAction(confirmAction)
        confirmationAlertView.addAction(cancelAction)
        present(confirmationAlertView, animated: true, completion: nil)
    }

    private func deselectSelectedRow() {
        if let indexPath = self.settingsTable.indexPathForSelectedRow {
            self.settingsTable.deselectRow(at: indexPath, animated: true)
        }
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if let selectedPath = settingsTable.indexPathForSelectedRow {
                if selectedPath.row == 0 && selectedPath.section == 0 {
                    //Name field can be of any value longer than 0
                    return text.count > 0
                } else {
                    return validateStringIsHexaDecimal(text)
                }
            } else {
                return validateStringIsHexaDecimal(text)
            }
        } else {
            return false
        }
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if range.length > 0 {
            //Going backwards, always allow deletion
            return true
        } else {
            if let selectedPath = settingsTable.indexPathForSelectedRow {
                if selectedPath.row == 0 && selectedPath.section == 0 {
                    //Name field can be of any value
                    return true
                } else {
                    return validateStringIsHexaDecimal(string)
                }
            } else {
                return validateStringIsHexaDecimal(string)
            }
        }
   }

    private func validateStringIsHexaDecimal(_ someText: String ) -> Bool {
        let value = someText.data(using: .utf8)![0]
        //Only allow HexaDecimal values 0->9, a->f and A->F or "x"
        return (value == 120 || value >= 48 && value <= 57) || (value >= 65 && value <= 70) || (value >= 97 && value <= 102)
    }

    // MARK: - Motion callbacks
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        let meshState = meshManager.stateManager().state()
        //Shaking the iOS device will generate a new Key
        if motion == .motionShake {
            let newKey = generateNewKey()
            meshState.netKeys[0].oldKey = meshState.netKeys[0].key
            meshState.netKeys[0].key = newKey
            self.updateProvisioningDataUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        meshManager = (UIApplication.shared.delegate as? AppDelegate)?.meshManager
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProvisioningDataUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        meshManager.stateManager().saveState()
        super.viewWillDisappear(animated)
    }

    // MARK: - UITableView delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4
        case 1: return 4
        case 2: return 1
        case 3: return 1
        case 4: return 2
        default: return 0
        }
   }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var aCell: UITableViewCell?
        if indexPath.section == 0 && indexPath.row == 3 {
            let toggleCell = tableView.dequeueReusableCell(withIdentifier: toggleReuseIdentifier, for: indexPath) as? ToggleSettingsTableViewCell
            toggleCell?.titleLabel.text = rowTitles[indexPath.section][indexPath.row]
            toggleCell?.toggleSwitch.isOn = (UserDefaults.standard.value(forKey: UserDefaultsKeys.autoRejoinKey) as? Bool) ?? false
            toggleCell?.setDelegate(self)
            aCell = toggleCell
        } else {
            aCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
            aCell!.textLabel?.text = rowTitles[indexPath.section][indexPath.row]
            aCell!.detailTextLabel?.text = self.contentForRowAtIndexPath(indexPath)
            if indexPath.section == 3 && indexPath.row == 0 {
                aCell!.detailTextLabel?.textColor = UIColor.red
            } else {
                aCell!.detailTextLabel?.textColor = UIColor.gray
            }
        }
        return aCell!
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 4 {
            //App version rows are readonly, no actions can be taken there
            return false
        }
        if (indexPath.section == 0 && indexPath.row == 3) {
            //Togglable settings cell is not selectable, only the switch can be tapped
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            if row == 0 {
                didSelectNetworkNameCell()
            } else if row == 1 {
                didSelectGlobalTTLCell()
            } else if row == 2 {
                didSelectUnicastAddressCell()
            }
        } else if section == 1 {
            if row == 0 {
                didSelectKeyCell()
            } else if row == 1 {
                didSelectKeyIndexCell()
            } else if row == 2 {
                didSelectFlagsCell()
            } else if row == 3 {
                didSelectIVIndexCell()
            }
        } else if section == 2 {
            didSelectAppKeysCell()
        } else if section == 3 {
            didSelectMeshResetCell()
        } else {
            deselectSelectedRow()
            return
        }
    }

    func contentForRowAtIndexPath(_ indexPath: IndexPath) -> String {
        let meshState = meshManager.stateManager().state()
        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            if row == 0 {
                return meshState.meshName
            } else if row == 1 {
                return "0x\(meshState.globalTTL.hexString())"
            } else if row == 2 {
                return "0x\(meshState.unicastAddress.hexString())"
            } else {
                return "N/A"
            }
        } else if section == 1 {
            if row == 0 {
                return "0x\(meshState.netKeys[0].key.hexString())"
            } else if row == 1 {
                return "0x\(meshState.netKeys[0].index.hexString())"
            } else if row == 2 {
                let flags = meshState.netKeys[0].flags
                var readableFlags = [String]()
                if flags[0] & 0x80 == 0x80 {
                    readableFlags.append("Key refresh phase: 2")
                } else {
                    readableFlags.append("Key refresh phase: 0")
                }
                if flags[0] & 0x40 == 0x40 {
                    readableFlags.append("IV Update: Active")
                } else {
                    readableFlags.append("IV Update: Normal")
                }
                return readableFlags.joined(separator: ", ")
            } else if row == 3 {
                return "0x\(meshState.netKeys[0].phase.hexString())"
            } else {
                return "N/A"
            }
        } else if section == 2 {
            if row == 0 {
                let keyCount = meshState.appKeys.count
                return "\(keyCount) \(keyCount != 1 ? "keys" : "key")"
            } else {
                return "N/A"
            }
        } else if section == 3 {
            if row == 0 {
                return "Forget Network"
            } else {
                return "N/A"
            }
        } else if section == 4 {
            if row == 0 {
                var versionNumber: String = "N/A"
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    versionNumber = "V \(version)"
                }
                return versionNumber
            } else if row == 1 {
                var buildNumber: String = "N/A"
                if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    buildNumber = build
                }
                return buildNumber
            } else {
                return "N/A"
            }
        } else {
            return "N/A"
        }
    }

    // MARK: - ToggleCellSettingsDelegate
    func didToggle(_ newState: Bool) {
        UserDefaults.standard.setValue(newState, forKey: UserDefaultsKeys.autoRejoinKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - UIPopoverPresentationDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showKeyManagerView" {
            if let destination = segue.destination as? AppKeyManagerTableViewController {
                destination.setMeshState(meshManager.stateManager())
            }
        }
    }
}
