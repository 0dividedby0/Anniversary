//
//  HomeViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit
import LocalAuthentication

class HomeViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var setNameView: UIView!
    @IBOutlet weak var newNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNameView.isHidden = true
        
        view.isUserInteractionEnabled = false
        let tabBarControllerItems = self.tabBarController?.tabBar.items
        
        if let tabArray = tabBarControllerItems {
            tabArray[0].isEnabled = false
            tabArray[1].isEnabled = false
            tabArray[2].isEnabled = false
            tabArray[3].isEnabled = false
            tabArray[4].isEnabled = false
        }
        // Do any additional setup after loading the view.
        authenticateWithBiometric()
    }
    
    func authenticateWithBiometric() {
        
        let localAuthContext = LAContext()
        let reasonText = "Authentication is required to sign into this App"
        var authError: NSError?
        
        if !localAuthContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            if let error = authError {
                print(error.localizedDescription)
            }
            
            return
        }
        
        localAuthContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonText, reply: {(success: Bool, error: Error?) -> Void in
            if success {
                print("Successfully authenticated")
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    let tabBarControllerItems = self.tabBarController?.tabBar.items
                    
                    if let tabArray = tabBarControllerItems {
                        tabArray[0].isEnabled = true
                        tabArray[1].isEnabled = true
                        tabArray[2].isEnabled = true
                        tabArray[3].isEnabled = true
                        tabArray[4].isEnabled = true
                    }
                }
            }
            else {
                if let error = error {
                    switch error {
                    case LAError.authenticationFailed:
                        print("Authenitcation failed")
                    default:
                        print(error.localizedDescription)
                    }
                }
                self.authenticateWithBiometric()
            }
        })
    }
    
    @IBAction func attentionButtonPushed(_ sender: Any) {
        if (defaults.string(forKey: "localUsername") == nil) {
            setNameView.isHidden = false
        }
        else {
            SocketIOManager.sharedInstance.sendNeedsAttention(sender: defaults.string(forKey: "localUsername") ?? "Default")
        }
    }
    
    @IBAction func setNameDoneButtonPushed(_ sender: Any) {
        setNameView.isHidden = true
        defaults.set(newNameField.text!, forKey: "localUsername")
        SocketIOManager.sharedInstance.updateDeviceToken(sender: defaults.string(forKey: "localUsername") ?? "Default", token: defaults.string(forKey: "deviceTokenString") ?? "nil")
    }
}

