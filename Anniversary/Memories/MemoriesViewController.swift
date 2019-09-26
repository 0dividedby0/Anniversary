//
//  MemoriesViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit

class MemoriesViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    struct memory {
        var id: String
        var title: String
        var date: String
        var dateType: NSDate
        var description: String
        var image: UIImage?
    }
    
    var memories: [memory] = []
    
    @IBOutlet weak var memoriesTableView: UITableView!
    @IBOutlet weak var newMemoryView: UIView!
    @IBOutlet weak var newMemoryTitle: UITextField!
    @IBOutlet weak var newMemoryDate: UITextField!
    @IBOutlet weak var newMemoryDescription: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        memoriesTableView.delegate = self;
        memoriesTableView.dataSource = self;
        
        SocketIOManager.sharedInstance.requestAllMemories()
        
        SocketIOManager.sharedInstance.receivedAllMemories(completionHandler: { (newMemories) -> Void in
            DispatchQueue.main.async {
                self.memories = []
                
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone.autoupdatingCurrent
                dateFormatter.dateFormat = "MMM d, yyyy"
                
                for newMemory in newMemories! {
                    let newDateType = dateFormatter.date(from: newMemory[1])! as NSDate
                    let memoryToAdd = memory(id: newMemory[3], title: newMemory[0], date: newMemory[1], dateType: newDateType, description: newMemory[2], image: UIImage(data: NSData(base64Encoded: newMemory[4], options: [])! as Data))
                    self.memories.append(memoryToAdd)
                }
                
                self.memories = self.memories.sorted(by: {
                    $0.dateType.timeIntervalSinceNow.isLess(than: $1.dateType.timeIntervalSinceNow)
                })
                
                self.memoriesTableView.reloadData()
            }
        })
        
        SocketIOManager.sharedInstance.getMemory(completionHandler: { (newTitle, newDate, newDescription, id, image) -> Void in
            DispatchQueue.main.async {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone.autoupdatingCurrent
                dateFormatter.dateFormat = "MMM d, yyyy"
                let newDateType = dateFormatter.date(from: newDate)! as NSDate
                
                let memoryToAdd = memory(id: id, title: newTitle, date: newDate, dateType: newDateType, description: newDescription, image: image)
                self.memories.append(memoryToAdd)
                
                self.memories = self.memories.sorted(by: {
                    $0.dateType.timeIntervalSinceNow.isLess(than: $1.dateType.timeIntervalSinceNow)
                    
                })
                
                self.memoriesTableView.reloadData()
            }
        })
        
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToDismissKeyboard)
    }

    @IBAction func addNewMemory(_ sender: Any) {
        newMemoryView.isHidden = false
    }
    @IBAction func cancelNewMemory(_ sender: Any) {
        newMemoryView.isHidden = true
        newMemoryTitle.text = ""
        newMemoryDate.text = ""
        newMemoryDescription.text = ""
    }
    @IBAction func createNewMemory(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let newDateType = dateFormatter.date(from: newMemoryDate.text!)! as NSDate
        
        var id = ""
        var idFound = true
        
        for i in 0...10000 {
            idFound = true
            for memory in memories {
                if ("Memory\(i)" == memory.id) {
                    idFound = false
                }
            }
            if (idFound) {
                id = "Memory\(i)"
                break
            }
        }
        
        let memoryToAdd = memory(id: id, title: newMemoryTitle.text!, date: newMemoryDate.text!, dateType: newDateType, description: newMemoryDescription.text!, image: nil)
        
        SocketIOManager.sharedInstance.sendMemory(sender: defaults.string(forKey: "localUsername") ?? "Default", title: memoryToAdd.title, date: memoryToAdd.date, description: memoryToAdd.description, id: id, image: memoryToAdd.image)
        
        newMemoryView.isHidden = true
        newMemoryTitle.text = ""
        newMemoryDate.text = ""
        newMemoryDescription.text = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "memoryToDetailView") {
            let destinationController = segue.destination as! MemoryDetailViewController
            let selectedIndex = self.memoriesTableView.indexPath(for: sender as! UITableViewCell)
            destinationController.currentMemory = memories[(selectedIndex?.row)!]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SocketIOManager.sharedInstance.requestAllMemories()
    }
}

extension MemoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row%2 == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "leftMemoryCellPrototype", for: indexPath) as! LeftMemoryCellPrototype
            cell.memoryDescription.sizeToFit()
            
            cell.memoryTitle.text = memories[indexPath.row].title
            cell.memoryDate.text = memories[indexPath.row].date
            cell.memoryDescription.text = memories[indexPath.row].description
            cell.memoryImage.image = memories[indexPath.row].image
            
            cell.selectionStyle = .none
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rightMemoryCellPrototype", for: indexPath) as! RightMemoryCellPrototype
            cell.memoryDescription.sizeToFit()
            
            cell.memoryTitle.text = memories[indexPath.row].title
            cell.memoryDate.text = memories[indexPath.row].date
            cell.memoryDescription.text = memories[indexPath.row].description
            cell.memoryImage.image = memories[indexPath.row].image
            
            cell.selectionStyle = .none
            return cell
        }
    }
    
    // Support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            SocketIOManager.sharedInstance.deleteMemory(id: memories[indexPath.row].id)
            memories.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

