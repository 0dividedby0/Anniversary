//
//  MemoriesViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit

class NewMemoryViewController: UIViewController {
    
    var trial = [["St. Louis","May 28, 2019","arch"],["Seattle","July 2, 2019","needle"],["Europe","July 2, 2021","mountains"]]

    @IBOutlet weak var newMemoryTitle: UITextField!
    @IBOutlet weak var newMemoryDescription: UITextView!
    @IBOutlet weak var newMemoryPhotoCollection: UICollectionView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        newMemoryPhotoCollection.delegate = self
        newMemoryPhotoCollection.dataSource = self
        newMemoryDescription.delegate = self
        
        newMemoryDescription.text = "Description"
        newMemoryDescription.textColor = UIColor.lightGray
        
        newMemoryTitle.attributedPlaceholder = NSAttributedString(string: "Title",
                                          attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapToDismissKeyboard.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapToDismissKeyboard)
    }
}

extension NewMemoryViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if newMemoryDescription.textColor == UIColor.lightGray {
            newMemoryDescription.text = nil
            newMemoryDescription.textColor = UIColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if newMemoryDescription.text.isEmpty {
            newMemoryDescription.text = "Description"
            newMemoryDescription.textColor = UIColor.lightGray
        }
    }
}

extension NewMemoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trial.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = newMemoryPhotoCollection.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath)
        
        //cell.backgroundView = UIImageView(image: UIImage(named: trial[indexPath.row][2]))
        
        return cell
    }
}
