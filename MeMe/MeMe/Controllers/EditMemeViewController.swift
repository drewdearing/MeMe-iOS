//
//  EditMemeViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

class EditMemeViewController: UIViewController {
    
    @IBOutlet weak var memeImageView: UIImageView!
    var selectedImage: UIImage!
    
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
            var ref: DocumentReference? = nil
            ref = Firestore.firestore().collection("post").addDocument(data: [
                "bottomText": "Meme",
                "downvotes": 0,
                "photoURL": "https://cdn.bulbagarden.net/upload/c/c6/094Gengar.png",
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
