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

class EditMemeViewController: UIViewController {
    
    @IBOutlet weak var memeImageView: UIImageView!
    var selectedImage: UIImage!
    @IBOutlet weak var descriptionField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if selectedImage != nil {
            memeImageView.image = selectedImage
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @IBAction func postMeme(_ sender: Any) {
        if let currentUser = Auth.auth().currentUser {
            self.addToStorage()
            /*
            var ref: DocumentReference? = nil
            ref = Firestore.firestore().collection("post").addDocument(data: [
                "bottomText": "Meme",
                "description": descriptionField.text!,
                "downvotes": 0,
                "photoURL": photoURL,
                "timestamp": NSDate(),
                "topText": "Dank",
                "uid": currentUser.uid,
                "upvotes": 0
                ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added with ID: \(ref!.documentID)")
                }
            }
            */
        }
    }
    
    func addToStorage(){
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let data = selectedImage.pngData()
        let imageName = NSUUID().uuidString
        print(imageName)
        let imageRef = storageRef.child("\(imageName).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        let uploadTask = imageRef.putData(data!, metadata: metadata) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            // You can also access to download URL after upload.
            imageRef.downloadURL { (url, error) in
                //do things that u want to do after download is done
                if let urlText = url?.absoluteString {
                    let currentUser = Auth.auth().currentUser
                    let download = urlText
                    var ref: DocumentReference? = nil
                    ref = Firestore.firestore().collection("post").addDocument(data: [
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
                            print("Document added with ID: \(ref!.documentID)")
                        }
                    }
                }
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "DoneViewVCIdentifier"){
            //we're going to the username VC
            postMeme(self)
            let mainVC: MainViewController = (segue.destination as! MainViewController)
        }
        
    }

    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
