//
//  ProfileSettingsViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/2/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class ProfileSettingsViewController: UIViewController {
    
    var user: User!
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var statusLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setNavigationBarItems()
    }
    
    private func setNavigationBarItems() {
        self.navigationItem.title = "Profile Settings"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(ProfileSettingsViewController.saveProfileEdits))
    }
    
    @objc func saveProfileEdits() {
        
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
