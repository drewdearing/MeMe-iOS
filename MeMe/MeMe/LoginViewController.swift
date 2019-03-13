//
//  LoginViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/7/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

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
                        self?.performSegue(withIdentifier: "LoginSegue", sender: self)
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

