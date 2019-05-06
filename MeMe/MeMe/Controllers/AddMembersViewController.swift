//
//  AddMembersViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class Container {
    let member: String
    let image: UIImage
    let profile: String
    let id: String
    var status: String
    var inGroup: Bool
    
    init (member: String, image: UIImage, profile: String, id: String) {
        self.member = member
        self.image = image
        self.profile = profile
        self.id = id
        self.status = ""
        self.inGroup = false
    }
    
    init (member: String, image: UIImage, profile: String, id: String, inGroup: Bool) {
        self.member = member
        self.image = image
        self.profile = profile
        self.id = id
        self.status = ""
        self.inGroup = inGroup
    }
}

protocol memberDelegate {
    func addMember(id: String)
}

class AddMembersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableViewCell: PotentialUserTableViewCell!
    @IBOutlet weak var potentialMembersTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var currentMembers: [String] = []
    private var potentialMembers: [String] = []
    private var currentPotentialMembers: [String] = []
    
    
    var loaded = false
    var groupname = String ()
    var groupddocid = String ()
    
    var delegate: memberDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.autocapitalizationType = .none
        setUpSearchBar()
        //setUpUsers()
        
        // Do any additional setup after loading the view.
        potentialMembersTableView.delegate = self
        potentialMembersTableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpUsers()
    }
    
    private func setUpUsers(){
        if let currentUser = Auth.auth().currentUser {
            let useHUD = self.potentialMembers.count <= 0
            if useHUD {
                DispatchQueue.main.async {
                    print("start")
                    SVProgressHUD.show(withStatus: "loading...")
                }
            }
            let q = DispatchQueue(label:"xyz")
            
            q.sync {
                let db = Firestore.firestore().collection("users").document(currentUser.uid).collection("followers")
                db.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            let userID = document.documentID
                            if !self.currentMembers.contains(userID) {
                                cache.getProfile(uid: userID) { (profile) in
                                    if let profile = profile {
                                        self.potentialMembers.append(profile.id)
                                    }
                                }
                            }
                        }
                    }
                    self.currentPotentialMembers = self.potentialMembers
                    SVProgressHUD.dismiss()
                    self.potentialMembersTableView.reloadData()
                }
            }
        }
    }
    
    private func setUpSearchBar(){
        searchBar.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPotentialMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "potentialMembersCellIdentifier", for: indexPath as IndexPath) as? PotentialUserTableViewCell
        let currentUser = currentPotentialMembers[indexPath.row]
        
        cache.getProfile(uid: currentUser) { (profile) in
            if let profile = profile {
                cell?.usernameLable.text = profile.username
                cell?.id = currentUser
                let profilePicURL = profile.profilePicURL
                cache.getImage(imageURL: profilePicURL, complete: { (profilePic) in
                    cell?.userProfileImageView.image = profilePic
                })
            }
        }
        return cell!
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            currentPotentialMembers = potentialMembers
            potentialMembersTableView.reloadData()
            return
        }
        currentPotentialMembers.removeAll()
        if let text = searchBar.text {
            for member in potentialMembers {
                cache.getProfile(uid: member) { (profile) in
                    if let profile = profile {
                        if profile.username.lowercased().contains(text.lowercased()) {
                            self.currentPotentialMembers.append(member)
                        }
                    }
                }
            }
        }
        potentialMembersTableView.reloadData()
        return
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentID = currentPotentialMembers[indexPath.row]
        let currentCell = potentialMembersTableView.cellForRow(at: indexPath) as! PotentialUserTableViewCell
        
        if (delegate != nil) {
            //group name you want to add user in
            let ref_group = Firestore.firestore().collection("groups").document(groupddocid).collection("usersInGroup").document(currentID)
            ref_group.setData([
                "lastActive": NSDate()
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            
            
            let ref_setuser = Firestore.firestore().collection("users").document(currentID).collection("groups").document(groupddocid).setData([
                "name": groupname
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            currentPotentialMembers.remove(at: indexPath.row)
            potentialMembers.removeAll { (user) -> Bool in
                return user == currentID
            }
            potentialMembersTableView.reloadData()
            delegate?.addMember(id: currentID)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
}
