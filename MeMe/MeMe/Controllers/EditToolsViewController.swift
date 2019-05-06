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
    func updateDesc(desc:String)
    func addMeme(post:PostData)
}

protocol BrushSettingsDelegate {
    func updateBrush(size:Float, hue:Float, red:CGFloat, green:CGFloat, blue:CGFloat)
}

protocol TextSettingsDelegate {
    func updateText(text:String, textSize:Float, textHue:Float)
}

class EditToolsViewController: UIViewController {
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet var imageView: UIImageView!
    
    var delegate:EditToolsDelegate!
    var desc:String!
    var selectedImage:UIImage!
    var croppedImage:UIImage!
    var originalSize:CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionField.text = desc
        croppedImage = cropImage()
        imageView.image = croppedImage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate.updateDesc(desc: descriptionField.text!)
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
    
    func cropImage() -> UIImage
    {
        UIGraphicsBeginImageContext(originalSize)
        let width = originalSize.width
        let height = selectedImage.size.height * width / selectedImage.size.width
        let y = (height - originalSize.height) / 2
        selectedImage.draw(in: CGRect(x: 0, y: -y, width: width, height: height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func addToStorage(){
        lockUI()
        SVProgressHUD.show(withStatus: "Posting...")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let image = croppedImage!
        let data = image.pngData()
        let color = image.averageColor!.toHexString()
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
                    self.addToFirestore(download: urlText, color: color, ref: ref)
                    self.passPost(imageName: imageName, download: urlText, color: color)
                }
            }
        }
    }
    
    func passPost(imageName:String, download:String, color:String){
        let currentUser = Auth.auth().currentUser
        Timestamp.getServerTime { (serverTime) in
            if let serverTime = serverTime {
                let data = PostData(id: imageName, uid: currentUser!.uid, color: color, timestamp: serverTime, upvotes: 0, downvotes: 0)
                SVProgressHUD.dismiss()
                self.delegate?.addMeme(post: data)
                self.dismiss(animated: true)
            }
        }
    }
    
    func addToFirestore(download:String, color:String, ref:DocumentReference){
        let currentUser = Auth.auth().currentUser
        let userPostRef = Firestore.firestore().collection("users").document(currentUser!.uid).collection("posts").document(ref.documentID)
        
        ref.setData([
            "description": self.descriptionField.text!,
            "downvotes": 0,
            "photoURL": download,
            "timestamp": NSDate(),
            "uid": currentUser!.uid,
            "upvotes": 0,
            "score": 0,
            "color": color
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref.documentID)")
            }
        }
        
        userPostRef.setData([
            "timestamp": NSDate(),
            "uid": currentUser!.uid,
            "color": color
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref.documentID)")
            }
        }
    }
}
