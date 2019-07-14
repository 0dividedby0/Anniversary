//
//  PlansViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit
import CoreData

class PlanDetailViewController: UIViewController {
    
    @IBOutlet weak var planLocationLabel: UILabel!
    @IBOutlet weak var planDateLabel: UILabel!
    @IBOutlet weak var planCountdownLabel: UILabel!
    @IBOutlet weak var planScrollView: UIScrollView!
    @IBOutlet weak var planPageControl: UIPageControl!
    
    @IBOutlet weak var editPlanView: UIView!
    @IBOutlet weak var editPlanNewName: UITextField!
    @IBOutlet weak var editPlanNewLocation: UITextField!
    @IBOutlet weak var editPlanNewDate: UITextField!
    
    @IBOutlet weak var addItemView: UIView!
    @IBOutlet weak var addItemTitleLabel: UILabel!
    @IBOutlet weak var addItemDescriptionField: UITextField!
    
    var slides: [PlanDetailSlide] = []
    var tableViews: [UITableView] = []
    var currentPlan: PlansViewController.plan? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        slides = createSlides()
        setupSlideScrollView(slides: slides)
        planScrollView.delegate = self
        
        planPageControl.numberOfPages = slides.count
        planPageControl.currentPage = 0
        view.bringSubviewToFront(planPageControl)
        
        if (currentPlan != nil) {
            self.title = currentPlan?.name
            planLocationLabel.text = currentPlan?.location
            planDateLabel.text = currentPlan?.date
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: updateCountdowns(timer:))
        timer.fire()
        
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToDismissKeyboard)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        setupSlideScrollView(slides: slides)
    }
    
    func createSlides() -> [PlanDetailSlide] {
        let slide1: PlanDetailSlide = Bundle.main.loadNibNamed("PlanDetailSlideView", owner: self, options: nil)?.first as! PlanDetailSlide
        slide1.slideTitle.text = "Activities"
        setupTableView(table: slide1.itemTableView)
        slide1.addItemButton.addTarget(self, action: #selector(addActivity), for: .touchUpInside)
        
        let slide2: PlanDetailSlide = Bundle.main.loadNibNamed("PlanDetailSlideView", owner: self, options: nil)?.first as! PlanDetailSlide
        slide2.slideTitle.text = "Flights"
        setupTableView(table: slide2.itemTableView)
        slide2.addItemButton.addTarget(self, action: #selector(addFlight), for: .touchUpInside)
        
        let slide3: PlanDetailSlide = Bundle.main.loadNibNamed("PlanDetailSlideView", owner: self, options: nil)?.first as! PlanDetailSlide
        slide3.slideTitle.text = "Map"
        setupTableView(table: slide3.itemTableView)
        slide3.addItemButton.addTarget(self, action: #selector(addLocation), for: .touchUpInside)
        
        let slide4: PlanDetailSlide = Bundle.main.loadNibNamed("PlanDetailSlideView", owner: self, options: nil)?.first as! PlanDetailSlide
        slide4.slideTitle.text = "Budget"
        setupTableView(table: slide4.itemTableView)
        slide4.addItemButton.addTarget(self, action: #selector(addBudget), for: .touchUpInside)
        
        let slide5: PlanDetailSlide = Bundle.main.loadNibNamed("PlanDetailSlideView", owner: self, options: nil)?.first as! PlanDetailSlide
        slide5.slideTitle.text = "Notes"
        setupTableView(table: slide5.itemTableView)
        slide5.addItemButton.addTarget(self, action: #selector(addNote), for: .touchUpInside)
        
        tableViews = [slide1.itemTableView, slide2.itemTableView, slide3.itemTableView, slide4.itemTableView, slide5.itemTableView]
        return [slide1, slide2, slide3, slide4, slide5]
    }
    
    @objc func addActivity(sender: UIButton!) {
        addItemTitleLabel.text = "New Activity"
        addItemView.isHidden = false
    }
    @objc func addFlight(sender: UIButton!) {
        addItemTitleLabel.text = "New Flight"
        addItemView.isHidden = false
    }
    @objc func addLocation(sender: UIButton!) {
        addItemTitleLabel.text = "New Location"
        addItemView.isHidden = false
    }
    @objc func addBudget(sender: UIButton!) {
        addItemTitleLabel.text = "New Budget"
        addItemView.isHidden = false
    }
    @objc func addNote(sender: UIButton!) {
        addItemTitleLabel.text = "New Note"
        addItemView.isHidden = false
    }
    
    @IBAction func cancelAddItemPushed(_ sender: Any) {
        addItemView.isHidden = true
        addItemDescriptionField.text = ""
    }
    @IBAction func saveAddItemPushed(_ sender: Any) {
        switch addItemTitleLabel.text {
        case "New Activity":
            currentPlan?.activities.append(addItemDescriptionField.text!)
            tableViews[0].reloadData()
            break
        case "New Flight":
            currentPlan?.flights.append(addItemDescriptionField.text!)
            tableViews[1].reloadData()
            break
        case "New Location":
            currentPlan?.map.append(addItemDescriptionField.text!)
            tableViews[2].reloadData()
            break
        case "New Budget":
            currentPlan?.budget.append(addItemDescriptionField.text!)
            tableViews[3].reloadData()
            break
        case "New Note":
            currentPlan?.notes.append(addItemDescriptionField.text!)
            tableViews[4].reloadData()
            break
        default:
            print("Did not recognize new item")
        }
        
        addItemView.isHidden = true
        addItemDescriptionField.text = ""
    }
    
    func setupTableView(table: UITableView) {
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .singleLine
        table.backgroundColor = .clear
    }
    
    func setupSlideScrollView(slides : [PlanDetailSlide]) {
        planScrollView.frame = CGRect(x: 10, y: 175, width: view.frame.width-20, height: planScrollView.frame.height)
        planScrollView.contentSize = CGSize(width: (planScrollView.frame.width) * CGFloat(slides.count), height: planScrollView.frame.height)
        planScrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: (planScrollView.frame.width) * CGFloat(i), y: 0, width: planScrollView.frame.width, height: planScrollView.frame.height)
            
            slides[i].layer.borderWidth = 1
            slides[i].layer.borderColor = UIColor.white.cgColor
            slides[i].layer.cornerRadius = 10
            slides[i].backgroundColor = .clear
            
            planScrollView.addSubview(slides[i])
        }
    }
    
    func updateCountdowns (timer: Timer) {
        let date = NSDate()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second, .month, .year, .day], from: date as Date)
        let currentDate = calendar.date(from: components)
        
        let timeLeft = calendar.dateComponents([.day,.hour,.minute,.second], from: currentDate!, to: currentPlan!.dateType as Date)
        planCountdownLabel.text = "\(timeLeft.day ?? 0)d \(timeLeft.hour ?? 0)h \(timeLeft.minute ?? 0)m \(timeLeft.second ?? 0)s"
    }
    
    @IBAction func editPlanButtonPushed(_ sender: Any) {
        editPlanNewName.text = currentPlan?.name
        editPlanNewLocation.text = currentPlan?.location
        editPlanNewDate.text = currentPlan?.date
        editPlanView.isHidden = false
    }
    @IBAction func cancelEditButtonPushed(_ sender: Any) {
        editPlanView.isHidden = true
    }
    @IBAction func saveEditButtonPushed(_ sender: Any) {
        currentPlan?.name = editPlanNewName.text!
        currentPlan?.location = editPlanNewLocation.text!
        currentPlan?.date = editPlanNewDate.text!
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let newDateType = dateFormatter.date(from: editPlanNewDate.text!)! as NSDate
        currentPlan?.dateType = newDateType
        
        self.title = currentPlan?.name
        planLocationLabel.text = currentPlan?.location
        planDateLabel.text = currentPlan?.date
        
        editPlanView.isHidden = true
    }
    
}

extension PlanDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        planPageControl.currentPage = Int(pageIndex)
    }
}

extension PlanDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case tableViews[0]:
            return (currentPlan?.activities.count)!
        case tableViews[1]:
            return (currentPlan?.flights.count)!
        case tableViews[2]:
            return (currentPlan?.map.count)!
        case tableViews[3]:
            return (currentPlan?.budget.count)!
        case tableViews[4]:
            return (currentPlan?.notes.count)!
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
    
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        
        switch tableView {
        case tableViews[0]:
            cell.textLabel?.text = currentPlan?.activities[indexPath.row]
        case tableViews[1]:
            cell.textLabel?.text = currentPlan?.flights[indexPath.row]
        case tableViews[2]:
            cell.textLabel?.text = currentPlan?.map[indexPath.row]
        case tableViews[3]:
            cell.textLabel?.text = currentPlan?.budget[indexPath.row]
        case tableViews[4]:
            cell.textLabel?.text = currentPlan?.notes[indexPath.row]
        default:
            print("Could not locate table view")
        }
        
        return cell
    }
}
