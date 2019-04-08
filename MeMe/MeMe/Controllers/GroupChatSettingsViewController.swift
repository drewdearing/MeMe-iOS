//
//  GroupChatSettingsViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

private let currentMemebersTableViewIdentifier = "CurrentMemebersTableView"
private let currentMemebersCellIdentifier = "Cell"

class GroupChatSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var groupChat: GroupChat!
    
    @IBOutlet weak var groupChatNameTextField: UITextField!
    @IBOutlet weak var groupChatNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var currentMemebersTableView: UITableView!
    private var currentMembers: [String] = []
    private var isEdit = false
    
    @IBOutlet weak var searchMemberBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentMemebersTableView.delegate = self
        currentMemebersTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentUserCell = tableView.dequeueReusableCell(withIdentifier: currentMemebersCellIdentifier, for: indexPath as IndexPath) as? CurrentUserTableViewCell
        
        let row = indexPath.row
        let user = currentMembers[row]
        
        currentUserCell?.setUsername(name: user)
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
            editButton.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
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
            editButton.setImage(#imageLiteral(resourceName: "edit"), for: .normal)
            groupChatNameLabel.text = name
            groupChatNameLabel.isHidden = false
            groupChatNameTextField.clearsOnBeginEditing = true
            groupChatNameTextField.placeholder = name
            groupChatNameTextField.isHidden = true
            groupChatNameTextField.textInputView.isUserInteractionEnabled = false
            groupChatNameTextField.resignFirstResponder()
        }
    }

    private func getMembers() {
        let currentUser = Auth.auth().currentUser
        
        let db = Firestore.firestore().collection("users")
        
        db.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            } else {
                for document in querySnapshot!.documents {
                    let temp = Firestore.firestore().collection("users").document(document.documentID).collection("groups").whereField("name", isEqualTo: "groupie")
                    temp.getDocuments() { (nameSnapshot, err) in
                        if let err2 = err {
                            print("Error getting documents: \(err2)")
                            return
                        } else {
                            for name in nameSnapshot!.documents {
                                let uname = document.get("username")
                                print (uname as! String)
                            }
                        }
                    }
                }
                
            }
        }
    }
    @IBAction func saveButton(_ sender: Any) {
        if (groupChatNameTextField.text != "") {
            let ref = Firestore.firestore().collection("groups").document()
            let currentUser = Auth.auth().currentUser
            ref.setData([
                "name": groupChatNameTextField.text
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added with ID: \(ref.documentID)")
                }
            }
            
            let ref_user = Firestore.firestore().collection("users")
            
            ref_user.document((currentUser?.uid)!).collection("groups").addDocument(data: [
                "name": groupChatNameTextField.text
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added")
                }
            }
            ref_user.document((currentUser?.uid)!).getDocument { (document, error) in
                if let username = document?.get("username") {
                    self.currentMembers.removeAll()
                    self.currentMembers.append(username as! String)
                    self.currentMemebersTableView.reloadData()
                }else{
                    print("error bitch")
                }
            }
        }
    }
}
