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

protocol addGroupsDelegate {
    func addGroup(name: String, id: String)
}

class GroupChatSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, memberDelegate {
    
    var groupChat: GroupChat!
    var delegate: addGroupsDelegate?
    
    @IBOutlet weak var groupChatNameTextField: UITextField!
    @IBOutlet weak var groupChatNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var currentMemebersTableView: UITableView!
    private var currentMembers: [String] = []
    private var isEdit = false
    
    var groupdocid = String ()
    var identity = String ()
    var groupName = String()
    var groupID = String()
    
    @IBOutlet weak var searchMemberBar: UISearchBar!
    @IBOutlet weak var saveLabel: UIBarButtonItem!
    @IBOutlet weak var vcTitle: UINavigationItem!
    
    @IBOutlet weak var seguebutton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        if (groupChatNameTextField.text == "" ){
            seguebutton.isHidden = true
        }
        
        if (identity == "settingsIdentifier") {
            seguebutton.isHidden = false
            saveLabel.isEnabled = false
            saveLabel.tintColor = UIColor.clear
            vcTitle.title = groupName
            groupChatNameLabel.text = groupName
            getMembers()
        }
        
        currentMemebersTableView.delegate = self	
        currentMemebersTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: currentMemebersCellIdentifier, for: indexPath as IndexPath) as? CurrentUserTableViewCell
        let currentUser = currentMembers[indexPath.row]
        
        cache.getProfile(uid: currentUser) { (profile) in
            if let profile = profile {
                cell?.usernameLabel.text = profile.username
                let profilePicURL = profile.profilePicURL
                cache.getImage(imageURL: profilePicURL, complete: { (profilePic) in
                    cell?.userProfileImageView.image = profilePic
                })
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user_id = currentMembers[indexPath.row]
        
        if (user_id != Auth.auth().currentUser?.uid) {
            let ref_delete = Firestore.firestore().collection("users").document(user_id).collection("groups").document(groupID).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
            
            let ref_user_delete = Firestore.firestore().collection("groups").document(groupID).collection("usersInGroup").document(user_id).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
            currentMembers.remove(at: indexPath.row)
            let ref_num_delete = Firestore.firestore().collection("groups").document(groupID).setData(["numMembers" : currentMembers.count], merge: true)
            
        }
        currentMemebersTableView.reloadData()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "addMembersSegue") {
            let vc: AddMembersViewController = segue.destination as! AddMembersViewController
            vc.delegate = self
            vc.currentMembers = self.currentMembers
            if (identity == "settingsIdentifier") {
                vc.groupname = self.groupName
                vc.groupddocid = self.groupID
            } else {
                vc.groupname = vcTitle.title!
                vc.groupddocid = self.groupdocid
            }
        }
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
        if groupChatNameTextField.text != "" {
            let name = groupChatNameTextField.text
            isEdit = false
            editButton.setImage(#imageLiteral(resourceName: "edit"), for: .normal)
            vcTitle.title = name
            groupChatNameLabel.text = name
            groupChatNameLabel.isHidden = false
            groupChatNameTextField.clearsOnBeginEditing = true
            groupChatNameTextField.placeholder = name
            groupChatNameTextField.isHidden = true
            groupChatNameTextField.textInputView.isUserInteractionEnabled = false
            groupChatNameTextField.resignFirstResponder()
            
            if (groupID != "") {
                let ref = Firestore.firestore().collection("groups").document(groupID)
                ref.setData(["name": name,], merge: true) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Name changed successful with ID: \(ref.documentID)")
                    }
                }
                
                let refUsersInGroup = ref.collection("usersInGroup")
                let ref_user = Firestore.firestore().collection("users")
                refUsersInGroup.getDocuments{ (querySnapshot, err) in
                    for document in querySnapshot!.documents {
                        ref_user.document(document.documentID).collection("groups").document(ref.documentID).setData([
                            "name": name
                        ]) { err in
                            if let err = err {
                                print("Error writing document: \(err)")
                            } else {
                                print("Document successfully written!")
                            }
                        }
                    }
                }
            }
        }
    }

    private func getMembers() {
            let q = DispatchQueue(label:"GroupSettings")
            q.sync {
                let db = Firestore.firestore().collection("groups")
                let ref = db.document(groupID).collection("usersInGroup")
                ref.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            let id = document.documentID
                            self.currentMembers.append(id)
                        }
                        self.currentMemebersTableView.reloadData()
                    }
                }
            }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        if (groupChatNameTextField.text != "") {
            let refid = createGroup()
            groupID = refid
            let ref_user = Firestore.firestore().collection("users")
            let currentUser = Auth.auth().currentUser
            ref_user.document((currentUser?.uid)!).getDocument { (document, error) in
                if let username = document?.get("username") {
                    self.currentMembers.append((currentUser?.uid)!)
                    self.currentMemebersTableView.reloadData()
                } else {
                    print("Error")
                }
            }
            seguebutton.isHidden = false
            saveLabel.isEnabled = false
            saveLabel.tintColor = UIColor.clear
            editButton.isHidden = false
            vcTitle.title = groupChatNameTextField.text
            if(delegate != nil) {
                delegate?.addGroup(name: groupChatNameTextField.text!, id: refid)
            }
        }
    }
    
    func addMember(id: String) {
        if groupID != "" {
            if !currentMembers.contains(id) {
                currentMembers.append(id)
                currentMemebersTableView.reloadData()
                let ref_group = Firestore.firestore().collection("groups").document(groupID)
                ref_group.setData(["numMembers" : currentMembers.count], merge: true) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Successfully add a member!")
                    }
                }
                print("Added")
            } else {
                print("Already added")
            }
        }
    }
    
    func createGroup () -> String {
        let currentUser = Auth.auth().currentUser
        let ref = Firestore.firestore().collection("groups").document()
        let refid = ref.documentID
        ref.setData([
            "name": groupChatNameTextField.text,
            "numMembers": 1
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                self.groupdocid = ref.documentID
                print("Document added with ID: \(ref.documentID)")
            }
        }
        
        ref.collection("usersInGroup").document((currentUser?.uid)!).setData([
            "lastActive": NSDate(),
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        
        let ref_user = Firestore.firestore().collection("users")
        ref_user.document((currentUser?.uid)!).collection("groups").document(refid).setData([
            "name": groupChatNameTextField.text
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        return refid
    }
}
