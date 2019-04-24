//
//  LoginViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/7/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

struct CurrentProfile: Codable {
    let username:String
    let email:String
    let numFollowing:Int
    let numFollowers:Int
    let profilePicURL:String
}

func getCurrentProfile() -> CurrentProfile?{
    let data = UserDefaults.standard.value(forKey: "currentProfile") as? Data
    if let data = data {
        let profile:CurrentProfile? = try? PropertyListDecoder().decode(CurrentProfile.self, from: data)
        return profile
    }
    return nil
}

class LoginViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    func unlockUI(){
        self.emailField.isUserInteractionEnabled = true
        self.passwordField.isUserInteractionEnabled = true
        self.loginButton.isUserInteractionEnabled = true
    }
    
    func lockUI(){
        emailField.isUserInteractionEnabled = false
        passwordField.isUserInteractionEnabled = false
        loginButton.isUserInteractionEnabled = false
    }
    
    @IBAction func login(_ sender: Any) {
        if let email = emailField.text {
            if let password = passwordField.text {
                lockUI()
                statusLabel.text = "Signing in..."
                Auth.auth().signIn(withEmail: email, password: password) { [weak self] user, error in
                    guard let strongSelf = self else { return }
                    if let user = user {
                        Firestore.firestore().collection("users").document(user.user.uid).getDocument(completion: { (doc, err) in
                            if let doc = doc {
                                if(doc.exists){
                                    print(doc.data())
                                    let data = doc.data()
                                    let username = data!["username"] as! String
                                    let email = data!["email"] as! String
                                    let profilePicURL = data!["profilePicURL"] as! String
                                    let numFollowing = Int(data!["numFollowing"] as! NSNumber)
                                    let numFollowers = Int(data!["numFollowers"] as! NSNumber)
                                    
                                    let newUser = CurrentProfile(username: username, email: email, numFollowing: numFollowing, numFollowers: numFollowers, profilePicURL: profilePicURL)
                                    UserDefaults.standard.set(try? PropertyListEncoder().encode(newUser), forKey: "currentProfile")
                                    print("LOGIN SEGUE")
                                    self?.performSegue(withIdentifier: "LoginSegue", sender: self)
                                }
                            }
                        })
                    }
                    else{
                        self?.statusLabel.text = "Could not sign in."
                    }
                    self?.unlockUI()
                }
            }
            else{
                statusLabel.text = "Password is required!"
            }
        }
        else{
            statusLabel.text = "Email is required!"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        statusLabel.text = ""
    }


}

