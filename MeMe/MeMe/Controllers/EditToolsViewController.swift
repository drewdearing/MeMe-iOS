//
//  EditToolsViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/10/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

protocol EditToolsDelegate {
    func updateTools(size:Float, hue:Float, red:CGFloat, green:CGFloat, blue:CGFloat, desc:String)
    func addMeme(post:FeedCellData, feed:Bool)
}

class EditToolsViewController: UIViewController {
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var brushSlider: UISlider!
    @IBOutlet weak var colorSlider: UISlider!
    var delegate:EditToolsDelegate!
    var desc:String!
    var red:Float!
    var blue:Float!
    var green:Float!
    var brush:Float!
    var hue:Float!
    var color:UIColor!
    var selectedImage:UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionField.text = desc
        brushSlider.maximumValue = 50.0
        brushSlider.minimumValue = 1.0
        brushSlider.setValue(brush, animated: false)
        colorSlider.setValue(hue, animated: false)
        color = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        colorSlider.thumbTintColor = color
    }
    
    @IBAction func colorSliderChanged(_ sender: Any) {
        colorSlider.thumbTintColor = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        color = colorSlider.thumbTintColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        delegate.updateTools(size: brushSlider.value, hue: colorSlider.value, red: r, green: g, blue: b, desc: descriptionField.text!)
    }
    
    func lockUI(){
        descriptionField.isEnabled = false
        doneButton.isEnabled = false
    }
    
    func unlockUI(){
        descriptionField.isEnabled = true
        doneButton.isEnabled = true
    }
    
    @IBAction func done(_ sender: Any) {
        addToStorage()
    }
    
    func addToStorage(){
        lockUI()
        SVProgressHUD.show(withStatus: "Posting...")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let data = selectedImage.pngData()
        let ref = Firestore.firestore().collection("post").document()
        let imageName = ref.documentID
        print(imageName)
        let imageRef = storageRef.child("\(imageName).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        imageRef.putData(data!, metadata: metadata) { (metadata, error) in
            imageRef.downloadURL { (url, error) in
                guard url != nil else {
                    // Uh-oh, an error occurred!
                    self.unlockUI()
                    return
                }
                //do things that u want to do after download is done
                if let urlText = url?.absoluteString {
                    self.addToFirestore(download: urlText, ref: ref)
                    self.passPost(imageName: imageName, download: urlText)
                }
            }
        }
    }
    
    func passPost(imageName:String, download:String){
        let currentUser = Auth.auth().currentUser
        if let profile = getCurrentProfile() {
            let data = FeedCellData(username: profile.username, description:  self.descriptionField.text!, uid: currentUser!.uid, post: imageName, imageURL: download, profilePicURL: profile.profilePicURL, upvotes: 0, downvotes: 0, timestamp: Timestamp(), upvoted:false, downvoted: false)
            SVProgressHUD.dismiss()
            delegate?.addMeme(post: data, feed:true)
            dismiss(animated: true)
        }
    }
    
    func addToFirestore(download:String, ref:DocumentReference){
        let currentUser = Auth.auth().currentUser
        ref.setData([
            "bottomText": "Meme",
            "description": self.descriptionField.text!,
            "downvotes": 0,
            "photoURL": download,
            "timestamp": NSDate(),
            "topText": "Dank",
            "uid": currentUser!.uid,
            "upvotes": 0
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref.documentID)")
            }
        }
    }
}
