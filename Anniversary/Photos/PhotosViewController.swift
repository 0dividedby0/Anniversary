//
//  PhotosViewController.swift
//  Anniversary
//
//  Created by Jason Halcomb on 5/22/19.
//  Copyright © 2019 jhalcomb. All rights reserved.
//

import UIKit
import SafariServices
import CoreData

class PhotosViewController: UIViewController {

    var isEditingPhotos = false
    
    var myCollectionView: UICollectionView!
    var imageArray=[UIImage]()
    var imageIdentifiers=[Int64]()
    var selectedImages = [Int]()
    
    @IBOutlet weak var editPhotosButton: UIBarButtonItem!
    @IBOutlet weak var editOptionsStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view
        
        let layout = UICollectionViewFlowLayout()
        
        myCollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        myCollectionView.delegate=self
        myCollectionView.dataSource=self
        myCollectionView.register(PhotoItemCell.self, forCellWithReuseIdentifier: "Cell")
        myCollectionView.backgroundColor=UIColor.init(white: 1, alpha: 0)
        self.view.addSubview(myCollectionView)
        self.view.sendSubviewToBack(myCollectionView)
        
        myCollectionView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue) | UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue)))
        
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let request: NSFetchRequest<ImageLibraryMO> = ImageLibraryMO.fetchRequest()
            let context = appDelegate.persistentContainer.viewContext
            do {
                let fetchedData = try context.fetch(request)
                for data in fetchedData {
                    let coreDataObject = data.image
                    let coreDataIdentifier = data.imageIdentifier
                    if let dataArray = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(coreDataObject!) as? NSArray {
                        for img in dataArray{
                            let extractedImg = UIImage(data: img as! Data)!
                            imageArray.append(extractedImg)
                            imageIdentifiers.append(coreDataIdentifier)
                        }
                    }
                }
            }
            catch {
                print(error)
            }
        }
        myCollectionView.reloadData()
    }
    
    @IBAction func editPhotosButtonPushed(_ sender: Any) {
        if (!isEditingPhotos) {
            editPhotosButton.title = "Done"
            editOptionsStackView.isHidden = false
            isEditingPhotos = true
        }
        else {
            editPhotosButton.title = "Edit"
            selectedImages = []
            editOptionsStackView.isHidden = true
            myCollectionView.reloadData()
            isEditingPhotos = false
        }
    }
    
    @IBAction func addPhotosButtonPushed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            
            imagePicker.delegate = self
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func savePhotosButtonPushed(_ sender: Any) {
        for i in selectedImages {
            UIImageWriteToSavedPhotosAlbum(imageArray[i], self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            print(error.localizedDescription)
        } else {
            print("Your image has been saved to your photos.")
        }
    }
    
    @IBAction func deletePhotosButtonPushed(_ sender: Any) {
        selectedImages.sort(by: {$0>$1})
        for i in selectedImages {
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let request: NSFetchRequest<ImageLibraryMO> = ImageLibraryMO.fetchRequest()
                let context = appDelegate.persistentContainer.viewContext
                do {
                    let fetchedData = try context.fetch(request)
                    for data in fetchedData {
                    let coreDataIdentifier = data.imageIdentifier
                        if (coreDataIdentifier == imageIdentifiers[i]) {
                            context.delete(data)
                            try context.save()
                        }
                    }
                }
                catch {
                    print(error)
                }
            }
            imageArray.remove(at: i)
            imageIdentifiers.remove(at: i)
            myCollectionView.reloadData()
        }
    }
}

extension PhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageArray.append(selectedImage)
            myCollectionView.reloadData()
            dismiss(animated: true, completion: nil)
            
            let CDataArray = NSMutableArray();
            var coreDataObject: Data?
            
            let data : NSData = NSData(data: selectedImage.pngData()!)
            CDataArray.add(data);
            
            do {
                coreDataObject = try NSKeyedArchiver.archivedData(withRootObject: CDataArray, requiringSecureCoding: false)
            }
            catch {
                print("Error")
            }
            
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let storedImageArray = ImageLibraryMO(context: appDelegate.persistentContainer.viewContext)
                storedImageArray.image = coreDataObject
                storedImageArray.imageIdentifier = Int64.random(in: 0 ..< 1000000)
                
                appDelegate.saveContext()
            }
        }
    }
}

extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell=collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoItemCell
        cell.img.image=imageArray[indexPath.item]
        
        if (selectedImages.firstIndex(of: indexPath.item) != nil) {
            cell.layer.borderWidth = 2
            cell.layer.borderColor = UIColor.gray.cgColor
        }
        else {
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor.gray.cgColor
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!isEditingPhotos) {
            let vc=ImagePreviewVC()
            vc.imgArray = self.imageArray
            vc.passedContentOffset = indexPath
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else {
            if (selectedImages.firstIndex(of: indexPath.item) == nil) {
                selectedImages.append(indexPath.item)
            }
            else {
                selectedImages.remove(at: selectedImages.firstIndex(of: indexPath.item)!)
            }
            myCollectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if (isEditingPhotos) {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 0
            cell?.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        //        if UIDevice.current.orientation.isPortrait {
        //            return CGSize(width: width/4 - 1, height: width/4 - 1)
        //        } else {
        //            return CGSize(width: width/6 - 1, height: width/6 - 1)
        //        }
        if DeviceInfo.Orientation.isPortrait {
            return CGSize(width: width/4 - 1, height: width/4 - 1)
        } else {
            return CGSize(width: width/6 - 1, height: width/6 - 1)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        myCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
}

class PhotoItemCell: UICollectionViewCell {
    
    var img = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        img.contentMode = .scaleAspectFill
        img.clipsToBounds=true
        self.addSubview(img)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        img.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct DeviceInfo {
    struct Orientation {
        // indicate current device is in the LandScape orientation
        static var isLandscape: Bool {
            get {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isLandscape
                    : UIApplication.shared.statusBarOrientation.isLandscape
            }
        }
        // indicate current device is in the Portrait orientation
        static var isPortrait: Bool {
            get {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isPortrait
                    : UIApplication.shared.statusBarOrientation.isPortrait
            }
        }
    }
}
