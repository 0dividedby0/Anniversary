//
//  HomeViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit
import LocalAuthentication

class SettingsViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    @IBOutlet weak var newNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (defaults.string(forKey: "localUsername") != nil) {
            newNameField.text = defaults.string(forKey: "localUsername")
        }
    }
    
    @IBAction func updateNameButtonPushed(_ sender: Any) {
        defaults.set(newNameField.text!, forKey: "localUsername")
        SocketIOManager.sharedInstance.updateDeviceToken(sender: defaults.string(forKey: "localUsername") ?? "Default", token: defaults.string(forKey: "deviceTokenString") ?? "nil")
    }
}

