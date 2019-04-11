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
    private var currentMembers: [Container] = []
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
        
        let row = indexPath.row
        let currentUser = currentMembers[indexPath.row]
        
        cell?.usernameLabel.text = currentUser.member
        cell?.userProfileImageView.image = currentUser.image
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        //should delete group document from user in database
        currentMembers.remove(at: row)
        currentMemebersTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "addMembersSegue") {
            let vc: AddMembersViewController = segue.destination as! AddMembersViewController
            vc.delegate = self
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
                            let name = document.get("username")
                            let pic = document.get("profileURL")
                            let id = document.documentID
                            let url = URL(string: pic as! String)
                            let data = try? Data(contentsOf: url!)
                            if let imageData = data {
                                let image = UIImage(data: imageData)
                                self.currentMembers.append(Container(member: name as! String, image: image as! UIImage, profile: pic as! String, id: id as! String, inGroup: true))
                            }
                        }
                    }
                    self.currentMemebersTableView.reloadData()
                }
            }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        if (groupChatNameTextField.text != "") {
            let currentUser = Auth.auth().currentUser
            let ref = Firestore.firestore().collection("groups").document()
            let refid = ref.documentID
            ref.setData([
                "name": groupChatNameTextField.text
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    self.groupdocid = ref.documentID
                    print("Document added with ID: \(ref.documentID)")
                }
            }
            
            ref.collection("usersInGroup").document((currentUser?.uid)!).setData([
                "username": getCurrentProfile()?.username,
                "profilePicURL": getCurrentProfile()?.profilePicURL
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
            
            
            
            ref_user.document((currentUser?.uid)!).getDocument { (document, error) in
                if let username = document?.get("username") {
                    self.currentMembers.removeAll()
                    let pic = document!.get("profilePicURL")
                    let url = URL(string: pic as! String)
                    let data = try? Data(contentsOf: url!)
                    if let imageData = data {
                        let image = UIImage(data: imageData)
                        self.currentMembers.append(Container(member: username as! String, image: image!, profile: document?.get("profilePicURL") as! String, id: (currentUser?.uid)!, inGroup: true))
                    }
                    self.currentMemebersTableView.reloadData()
                } else {
                    print("error bitch")
                }
            }
            
            seguebutton.isHidden = false
            saveLabel.isEnabled = false
            saveLabel.tintColor = UIColor.clear
            editButton.isHidden = false
            vcTitle.title = groupChatNameTextField.text
            
            if(delegate != nil) {
                delegate?.addGroup(name: groupChatNameTextField.text!, id: refid)
            }else{
            }
        }
    }
    
    func addMember(name: String, container: Container) {
        print(container)
        if (!currentMembers.contains {
                $0.id == container.id
            }) {
            currentMembers.append(container)
            container.status = "Added!"
        }else{
            container.status = "Already added!"
        }
        container.inGroup = true
        currentMemebersTableView.reloadData()
    }
}
