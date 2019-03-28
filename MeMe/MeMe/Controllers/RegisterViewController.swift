//
//  RegisterViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    func unlockUI(){
        self.userNameField.isUserInteractionEnabled = true
        self.emailField.isUserInteractionEnabled = true
        self.passwordField.isUserInteractionEnabled = true
        self.registerButton.isUserInteractionEnabled = true
    }
    
    func lockUI(){
        userNameField.isUserInteractionEnabled = false
        emailField.isUserInteractionEnabled = false
        passwordField.isUserInteractionEnabled = false
        registerButton.isUserInteractionEnabled = false
    }
    
    @IBAction func register(_ sender: Any) {
        if let email = emailField.text{
            if let username = userNameField.text{
                if let password = passwordField.text  {
                    lockUI()
                    statusLabel.text = "loading..."
                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                        if let user = authResult {
                            print(user.user.uid)
                            Firestore.firestore().collection("users").document(user.user.uid).setData([
                                "username": username,
                                "email": email,
                                "followers": [String](),
                                "following": [String](),
                                "numFollowing": 0,
                                "numFollowers": 0,
                                "posts": [String](),
                                "profilePicURL": "https://cdn.bulbagarden.net/upload/c/c6/094Gengar.png"
                            ]) { err in
                                if let err = err {
                                    user.user.delete { error in
                                        if let error = error {
                                            print("data corrupted!")
                                        } else {
                                            self.statusLabel.text = "Could not create user!"
                                        }
                                    }
                                } else {
                                    self.statusLabel.text = "User created!"
                                    //go to home
                                    self.performSegue(withIdentifier: "RegisterSegue", sender: self)
                                }
                                self.unlockUI()
                            }
                        }
                        else{
                            self.statusLabel.text = error!.localizedDescription
                            self.unlockUI()
                        }
                    }
                }
                else{
                    statusLabel.text = "password is required!"
                }
            }
            else{
                statusLabel.text = "username is required!"
            }
        }
        else{
            statusLabel.text = "email is required!"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = ""
        // Do any additional setup after loading the view.
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
