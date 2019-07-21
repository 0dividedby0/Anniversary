//
//  PlansViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit
import CoreData

class PlansViewController: UIViewController {
    
    @IBOutlet weak var plansTableView: UITableView!
    @IBOutlet weak var newPlanView: UIView!
    @IBOutlet weak var newPlanNameTextField: UITextField!
    @IBOutlet weak var newPlanLocationTextField: UITextField!
    @IBOutlet weak var newPlanDateTextField: UITextField!
    
    let defaults = UserDefaults.standard
    
    struct plan {
        var id: String
        var name: String
        var location: String
        var date: String
        var dateType: NSDate
        var timeUntil: String
        var activities: [String]
        var flights: [String]
        var map: [String]
        var budget: [String]
        var notes: [String]
    }
    
    var plans: [plan] = []
    var touching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        plansTableView.dataSource = self
        plansTableView.delegate = self
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateCountdowns(timer:))
        timer.fire()
        
        SocketIOManager.sharedInstance.requestAllPlans()
        
        SocketIOManager.sharedInstance.receivedAllPlans(completionHandler: { (newPlans) -> Void in
            DispatchQueue.main.async {
                self.plans = []
                
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone.autoupdatingCurrent
                dateFormatter.dateFormat = "MMM d, yyyy"
                
                for newPlan in newPlans! {
                    let newDateType = dateFormatter.date(from: newPlan[2][0])! as NSDate
                    let planToAdd = plan(id: newPlan[8][0], name: newPlan[0][0], location: newPlan[1][0], date: newPlan[2][0], dateType: newDateType, timeUntil: "", activities: newPlan[3], flights: newPlan[4], map: newPlan[5], budget: newPlan[6], notes: newPlan[7])
                    self.plans.append(planToAdd)
                }
                
                self.updateCountdowns(timer: Timer())
                
                self.plans = self.plans.sorted(by: {
                    $0.dateType.timeIntervalSinceNow.isLess(than: $1.dateType.timeIntervalSinceNow)
                })
                
                self.plansTableView.reloadData()
            }
        })
        
        SocketIOManager.sharedInstance.getPlan(completionHandler: { (name, location, date, activities, flights, map, budget, notes, id) -> Void in
            DispatchQueue.main.async {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone.autoupdatingCurrent
                dateFormatter.dateFormat = "MMM d, yyyy"
                
                let newDateType = dateFormatter.date(from: date)! as NSDate
                let planToAdd = plan(id: id, name: name, location: location, date: date, dateType: newDateType, timeUntil: "", activities: activities, flights: flights, map: map, budget: budget, notes: notes)
                self.plans.append(planToAdd)
                self.updateCountdowns(timer: Timer())
                
                self.plans = self.plans.sorted(by: {
                    $0.dateType.timeIntervalSinceNow.isLess(than: $1.dateType.timeIntervalSinceNow)
                })
                
                self.plansTableView.reloadData()
            }
        })
        
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToDismissKeyboard)
    }
    
    @IBAction func addPlanButtonPushed(_ sender: Any) {
        newPlanView.isHidden = false
    }
    
    @IBAction func createNewPlan(_ sender: Any) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let newDateType = dateFormatter.date(from: newPlanDateTextField.text!)! as NSDate
        
        var id = ""
        var idFound = true
        
        for i in 0...10000 {
            idFound = true
            for plan in plans {
                if ("Plan\(i)" == plan.id) {
                    idFound = false
                }
            }
            if (idFound) {
                id = "Plan\(i)"
                break
            }
        }
        
        let planToAdd = plan(id: id, name: newPlanNameTextField.text!,location: newPlanLocationTextField.text!,date: newPlanDateTextField.text!,dateType: newDateType,timeUntil:"",activities: [],flights: [],map: [],budget: [],notes: [])
        
        SocketIOManager.sharedInstance.sendPlan(sender: defaults.string(forKey: "localUsername") ?? "Default", name: planToAdd.name, location: planToAdd.location, date: planToAdd.date, activities: planToAdd.activities, flights: planToAdd.flights, map: planToAdd.map, budget: planToAdd.budget, notes: planToAdd.notes, id: planToAdd.id)
        
        newPlanView.isHidden = true
        newPlanNameTextField.text = ""
        newPlanLocationTextField.text = ""
        newPlanDateTextField.text = ""
    }
    
    func updateCountdowns (timer: Timer) {
        let date = NSDate()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second, .month, .year, .day], from: date as Date)
        let currentDate = calendar.date(from: components)
        
        for i in 0..<plans.count {
            let timeLeft = calendar.dateComponents([.day,.hour,.minute,.second], from: currentDate!, to: plans[i].dateType as Date)
            plans[i].timeUntil = "\(timeLeft.day ?? 0)d \(timeLeft.hour ?? 0)h \(timeLeft.minute ?? 0)m \(timeLeft.second ?? 0)s"
        }
        
        if (!touching) { plansTableView.reloadData() }
    }
    
    @IBAction func cancelNewPlan(_ sender: Any) {
        newPlanView.isHidden = true
        newPlanNameTextField.text = ""
        newPlanLocationTextField.text = ""
        newPlanDateTextField.text = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "planToDetailView") {
            let destinationController = segue.destination as! PlanDetailViewController
            let selectedIndex = self.plansTableView.indexPath(for: sender as! UITableViewCell)
            destinationController.currentPlan = plans[(selectedIndex?.row)!]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SocketIOManager.sharedInstance.requestAllPlans()
    }
}

extension PlansViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return plans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "planCellPrototype", for: indexPath) as! PlanCellPrototype
        
        cell.nameLabel.text = plans[indexPath.row].name
        cell.locationLabel.text = plans[indexPath.row].location
        cell.dateLabel.text = plans[indexPath.row].date
        cell.countdownLabel.text = plans[indexPath.row].timeUntil
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // Support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            SocketIOManager.sharedInstance.deletePlan(id: plans[indexPath.row].id)
            plans.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        touching = true
    }
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        touching = false
    }
}
