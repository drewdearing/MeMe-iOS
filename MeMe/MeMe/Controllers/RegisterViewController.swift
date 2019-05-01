//
//  RegisterViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

struct RegisterFields {
    let name:String
    let password:String
    let email:String
    let image:UIImage
}

class RegisterViewController: UIViewController, ImagePickerDelegate {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var imageButton: UIButton!
    var imagePicker:ImagePicker!
    var selectedImage:UIImage?
    
    func unlockUI(){
        self.userNameField.isEnabled = true
        self.emailField.isEnabled = true
        self.passwordField.isEnabled = true
        self.registerButton.isEnabled = true
        self.imageButton.isEnabled = true
    }
    
    func lockUI(){
        userNameField.isEnabled = false
        emailField.isEnabled = false
        passwordField.isEnabled = false
        registerButton.isEnabled = false
        imageButton.isEnabled = false
    }
    
    func getEmail() -> String? {
        if let email = emailField.text {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if emailTest.evaluate(with: email) {
                return email
            }
        }
        return nil
    }
    
    func getName() -> String? {
        if let name = userNameField.text {
            if name.count > 0 {
                return name
            }
        }
        return nil
    }
    
    func getPassword() -> String? {
        if let password = passwordField.text {
            if password.count >= 6 {
                return password
            }
        }
        return nil
    }
    
    func getRequiredFields(complete: @escaping (RegisterFields?) -> Void){
        print("enter")
        if let email = getEmail(){
            if let name = getName() {
                if let password = getPassword() {
                    if let image = selectedImage {
                        SVProgressHUD.show(withStatus: "Loading...")
                        let requiredFields = RegisterFields(name: name, password: password, email: email, image: image)
                        complete(requiredFields)
                    }
                    else{
                        statusLabel.text = "Please select an avatar!"
                        self.unlockUI()
                        complete(nil)
                    }
                }
                else{
                    statusLabel.text = "Your password should be 6 characters!"
                    self.unlockUI()
                    complete(nil)
                }
            }
            else{
                statusLabel.text = "Please enter a display name!"
                self.unlockUI()
                complete(nil)
            }
        }
        else{
            statusLabel.text = "Please enter a valid email!"
            self.unlockUI()
            complete(nil)
        }
    }
    
    private func uploadImage(image:UIImage, complete: @escaping (String?) -> Void){
        let currentUser = Auth.auth().currentUser
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let data = image.pngData()
        let imageName = "profile_" + currentUser!.uid
        print(imageName)
        let imageRef = storageRef.child("\(imageName).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        imageRef.putData(data!, metadata: metadata) { (metadata, error) in
            imageRef.downloadURL { (url, error) in
                guard url != nil else {
                    complete(nil)
                    return
                }
                //do things that u want to do after download is done
                if let urlText = url?.absoluteString {
                    complete(urlText)
                }
                else{
                    complete(nil)
                }
            }
        }
    }
    
    @IBAction func register(_ sender: Any) {
        lockUI()
        self.statusLabel.text = "Loading..."
        getRequiredFields { (requiredFields) in
            if let fields = requiredFields {
                Auth.auth().createUser(withEmail: fields.email, password: fields.password) { authResult, error in
                    if let user = authResult {
                        print(user.user.uid)
                        self.uploadImage(image: fields.image) { (url) in
                            if let avatarURL = url {
                                Firestore.firestore().collection("users").document(user.user.uid).setData([
                                    "username": fields.name,
                                    "email": fields.email,
                                    "followers": [String](),
                                    "following": [String](),
                                    "numFollowing": 0,
                                    "numFollowers": 0,
                                    "posts": [String](),
                                    "profilePicURL": avatarURL
                                ]) { err in
                                    if let err = err {
                                        SVProgressHUD.dismiss()
                                        user.user.delete { error in
                                            if let error = error {
                                                print("data corrupted!")
                                            } else {
                                                self.statusLabel.text = "Could not create user!"
                                            }
                                        }
                                    } else {
                                        SVProgressHUD.dismiss()
                                        self.statusLabel.text = "User created!"
                                        let newUser = CurrentProfile(username: fields.name, email: fields.email, numFollowing: 0, numFollowers: 0, profilePicURL: avatarURL)
                                        UserDefaults.standard.set(try? PropertyListEncoder().encode(newUser), forKey: "currentProfile")
                                        //go to home
                                        self.performSegue(withIdentifier: "RegisterSegue", sender: self)
                                    }
                                    self.unlockUI()
                                }
                            }
                            else{
                                SVProgressHUD.dismiss()
                                self.unlockUI()
                                self.statusLabel.text = "Could not upload image!"
                            }
                        }
                    }
                    else{
                        SVProgressHUD.dismiss()
                        self.statusLabel.text = error!.localizedDescription
                        self.unlockUI()
                    }
                }
            }
        }
    }
    
    @IBAction func selectImage(_ sender: Any) {
        self.imagePicker.present(from: sender as! UIView)
    }
    
    func didSelect(image: UIImage?) {
        imageButton.backgroundColor = UIColor(red: 32/255, green: 129/255, blue: 66/255, alpha: 1)
        imageButton.setTitleColor(.lightGray, for: .normal)
        selectedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = ""
        self.imagePicker = ImagePicker(presentationController: self, delegate: self, editAllowed: true)
    }

}
