//
//  EditMemeViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SVProgressHUD

protocol NewMemeDelegate {
    func addMeme(post: FeedCellData, feed:Bool)
}

class EditMemeViewController: UIViewController {
    
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var selectedImage: UIImage!
    var delegate:NewMemeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if selectedImage != nil {
            memeImageView.image = selectedImage
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func postMeme(_ sender: Any) {
        addToStorage()
    }
    
    func lockUI(){
        descriptionField.isUserInteractionEnabled = false
        doneButton.isEnabled = false
    }
    
    func unlockUI(){
        descriptionField.isEnabled = true
        doneButton.isEnabled = true
    }
    
    func addToStorage(){
        lockUI()
        SVProgressHUD.show(withStatus: "Loading...")
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
            let data = FeedCellData(username: profile.username, description: self.descriptionField.text!, uid: currentUser!.uid, post: imageName, imageURL: download, profilePicURL: profile.profilePicURL, upvotes: 0, downvotes: 0, timestamp: Timestamp(), upvoted:false, downvoted: false)
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
