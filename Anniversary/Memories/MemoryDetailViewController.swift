//
//  MemoriesViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit

class MemoryDetailViewController: UIViewController {
    
    @IBOutlet weak var memoryTitle: UILabel!
    @IBOutlet weak var memoryDate: UILabel!
    @IBOutlet weak var memoryDescription: UILabel!
    @IBOutlet weak var memoryBackgroundImage: UIImageView!
    
    @IBOutlet weak var editMemoryView: UIView!
    @IBOutlet weak var editMemoryTitle: UITextField!
    @IBOutlet weak var editMemoryDate: UITextField!
    @IBOutlet weak var editMemoryDescription: UITextField!
    
    let defaults = UserDefaults.standard
    
    var currentMemory: MemoriesViewController.memory? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if (currentMemory != nil) {
            memoryTitle.text = currentMemory?.title
            memoryDate.text = currentMemory?.date
            memoryDescription.text = currentMemory?.description
            memoryBackgroundImage.image = currentMemory?.image
        }
        
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToDismissKeyboard)
    }

    @IBAction func editMemory(_ sender: Any) {
        editMemoryTitle.text = currentMemory?.title
        editMemoryDate.text = currentMemory?.date
        editMemoryDescription.text = currentMemory?.description
        editMemoryView.isHidden = false
    }
    @IBAction func addPhotoToMemory(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            
            imagePicker.delegate = self
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    @IBAction func saveEditedMemory(_ sender: Any) {
        currentMemory?.title = editMemoryTitle.text!
        currentMemory?.date = editMemoryDate.text!
        currentMemory?.description = editMemoryDescription.text!
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let newDateType = dateFormatter.date(from: editMemoryDate.text!)! as NSDate
        currentMemory?.dateType = newDateType
        
        memoryTitle.text = currentMemory?.title
        memoryDate.text = currentMemory?.date
        memoryDescription.text = currentMemory?.description
        
        editMemoryView.isHidden = true
    }
    @IBAction func cancelEditedMemory(_ sender: Any) {
        editMemoryView.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SocketIOManager.sharedInstance.sendMemory(sender: defaults.string(forKey: "localUsername") ?? "Default", title: currentMemory!.title, date: currentMemory!.date, description: currentMemory!.description, id: currentMemory!.id, image: currentMemory!.image)
    }
}

extension MemoryDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            currentMemory?.image = UIImage(data: selectedImage.jpegData(compressionQuality: 0.0)!)
            memoryBackgroundImage.image = UIImage(data: selectedImage.jpegData(compressionQuality: 0.0)!)
            dismiss(animated: true, completion: nil)
        }
    }
}
