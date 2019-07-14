//
//  MessagingViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit

struct message {
    var sender: String
    var message: String
    var date: String
}

class MessagingViewController: UIViewController {
    
    @IBOutlet weak var setNameView: UIView!
    @IBOutlet weak var newNameField: UITextField!
    
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var messagesNavigationBar: UINavigationItem!
    @IBOutlet weak var newMessageTextField: UITextField!
    
    var messages: [message] = []
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (defaults.string(forKey: "localUsername") == nil) {
            setNameView.isHidden = false
        }
        else {
            initializeChat()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @IBAction func setNewName(_ sender: Any) {
        setNameView.isHidden = true
        defaults.set(newNameField.text!, forKey: "localUsername")
        SocketIOManager.sharedInstance.updateDeviceToken(sender: defaults.string(forKey: "localUsername") ?? "Default", token: defaults.string(forKey: "deviceTokenString") ?? "nil")
        initializeChat()
    }
    
    func initializeChat() {
        // Do any additional setup after loading the view.
        messagesNavigationBar.title = defaults.string(forKey: "localUsername")!
        messagesTableView.delegate = self
        messagesTableView.dataSource = self
        
        SocketIOManager.sharedInstance.requestAllMessages()
        
        SocketIOManager.sharedInstance.receivedAllMessages(completionHandler: { (newMessages) -> Void in
            DispatchQueue.main.async {
                self.messages = []
                for newMessage in newMessages ?? [["System", "No new messages!"]] {
                    let messageToAdd = message(sender: newMessage[0], message: newMessage[1], date: newMessage[2])
                    self.messages.append(messageToAdd)
                }
                self.messagesTableView.reloadData()
                if (self.messages.count > 0) {
                    let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                    self.messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        })
        
        SocketIOManager.sharedInstance.getMessage(completionHandler: { (newSender, newMessage) -> Void in
            DispatchQueue.main.async {
                let messageToAdd = message(sender: newSender, message: newMessage, date: Date().description)
                self.messages.append(messageToAdd)
                self.messagesTableView.reloadData()
                let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                self.messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        })
        
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToDismissKeyboard)
    }

    @IBAction func sendNewMessage(_ sender: Any) {
        SocketIOManager.sharedInstance.sendMessage(sender: defaults.string(forKey: "localUsername") ?? "Default", message: newMessageTextField.text ?? "Hi", date: Date().description)
        newMessageTextField.text = ""
    }
    
}

extension MessagingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (messages[indexPath.row].sender == defaults.string(forKey: "localUsername")) {
            let cell = messagesTableView.dequeueReusableCell(withIdentifier: "sentMessageCellPrototype", for: indexPath) as! SentMessageCellPrototype
            cell.messageText.text = messages[indexPath.row].message
            cell.messageDescription.text = messages[indexPath.row].date
            return cell
        }
        else {
            let cell = messagesTableView.dequeueReusableCell(withIdentifier: "receivedMessageCellPrototype", for: indexPath) as! ReceivedMessageCellPrototype
            cell.messageText.text = messages[indexPath.row].message
            cell.messageDescription.text = messages[indexPath.row].sender + " - " + messages[indexPath.row].date.description
            return cell
        }
    }
    
    // Support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            messages.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
