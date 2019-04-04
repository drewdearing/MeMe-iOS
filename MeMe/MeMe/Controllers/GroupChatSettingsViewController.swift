//
//  GroupChatSettingsViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

private let currentMemebersTableViewIdentifier = "CurrentMemebersTableView"
private let potentialMembersTableViewIdentifier = "PotentialMembersTableView"

private let currentMemebersCellIdentifier = ""
private let potentialMembersCellIdentifier = ""

class GroupChatSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var groupChat: GroupChat!
    
    @IBOutlet weak var groupChatNameTextField: UITextField!
    @IBOutlet weak var groupChatNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var currentMemebersTableView: UITableView!
    private var currentMembers: [User] = []
    private var isEdit = false
    
    @IBOutlet weak var searchMemberBar: UISearchBar!
    
    
    //@IBOutlet weak var potentialMembersTableView: UITableView!
    //private var potentialMembers: [User] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        currentMemebersTableView.delegate = self
        currentMemebersTableView.dataSource = self
        
        //potentialMembersTableView.delegate = self
        //potentialMembersTableView.dataSource = self
        
        //setNavigationBarItems()
    }
    
    private func setNavigationBarItems() {
        self.navigationItem.title = "Group Settings"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(GroupChatSettingsViewController.saveGroupChatSettings))
    }
    
    @objc func saveGroupChatSettings() {
        // Save Groupchat settings and got to the new Group Chat
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentUserCell = tableView.dequeueReusableCell(withIdentifier: currentMemebersCellIdentifier, for: indexPath as IndexPath) as? CurrentUserTableViewCell
            
        let row = indexPath.row
        let user = currentMembers[row]
            
        //            currentUserCell.imageView = user
        //            currentUserCell?.usernameLabel.text = user.username
        return currentUserCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        currentMembers.remove(at: row)
        currentMemebersTableView.reloadData()
    }
    
    @IBAction func editButton(_ sender: Any) {
        if(isEdit) {
            saveName()
        } else {
            //editButton.setImage(, for: .normal)
            editButton.setImage(#imageLiteral(resourceName: "home"), for: .normal)
            groupChatNameLabel.isHidden = true
            groupChatNameTextField.isHidden = false
            groupChatNameTextField.textInputView.isUserInteractionEnabled = true
            groupChatNameTextField.becomeFirstResponder()
            isEdit = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        saveName()
    }
    
    func saveName() {
        if let name = groupChatNameTextField.text {
            isEdit = false
            editButton.setImage(#imageLiteral(resourceName: "settings"), for: .normal)
            groupChatNameLabel.text = name
            groupChatNameLabel.isHidden = false
            groupChatNameTextField.clearsOnBeginEditing = true
            groupChatNameTextField.placeholder = name
            groupChatNameTextField.isHidden = true
            groupChatNameTextField.textInputView.isUserInteractionEnabled = false
            groupChatNameTextField.resignFirstResponder()
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
