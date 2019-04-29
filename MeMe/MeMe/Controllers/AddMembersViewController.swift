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
    
    private var potentialMembers: [Container] = []
    private var currentPotentialMembers: [Container] = []
    
    
    var loaded = false
    var groupname = String ()
    var groupddocid = String ()
    
    var delegate: memberDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.autocapitalizationType = .none
        setUpSearchBar()
        setUpUsers()
        
        // Do any additional setup after loading the view.
        potentialMembersTableView.delegate = self
        potentialMembersTableView.dataSource = self
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
                let db = Firestore.firestore().collection("users")
                db.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            let name = document.get("username")
                            let pic = document.get("profilePicURL")
                            let id = document.documentID
                            let url = URL(string: pic as! String)
                            let data = try? Data(contentsOf: url!)
                            if let imageData = data {
                                let image = UIImage(data: imageData)
                                self.potentialMembers.append(Container(member: name as! String, image: image as! UIImage, profile: pic as! String, id: id as! String))
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
        cell?.usernameLable.text = currentUser.member
        cell?.userProfileImageView.image = currentUser.image
        
        cell?.id = currentUser.id
        cell?.addlabel.text = currentUser.status
        if(currentUser.inGroup) {
            cell?.addlabel.isHidden = false
        } else {
            cell?.addlabel.isHidden = true
        }
        return cell!
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            currentPotentialMembers = potentialMembers
            potentialMembersTableView.reloadData()
            return
        }
        currentPotentialMembers = potentialMembers.filter({names -> Bool in
            guard let text = searchBar.text else { return false}
            return names.member.contains(text)
        })
        potentialMembersTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = currentPotentialMembers[indexPath.row]
        let cellname = currentPotentialMembers[indexPath.row].member
        let currentCell = potentialMembersTableView.cellForRow(at: indexPath) as! PotentialUserTableViewCell
        
        if (delegate != nil) {
            //group name you want to add user in
            print(groupname)
            let userid = currentCell.id
            let name = currentCell.usernameLable.text
            let ref_group = Firestore.firestore().collection("groups").document(groupddocid).collection("usersInGroup").document(userid).setData([
                "username": name,
                "profilePicURL": current.profile
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            
            
            let ref_setuser = Firestore.firestore().collection("users").document(userid).collection("groups").document(groupddocid).setData([
                "name": groupname
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            	
            delegate?.addMember(id: userid)
            currentCell.addlabel.adjustsFontSizeToFitWidth = true
            currentCell.addlabel.text = current.status
            currentCell.addlabel.isHidden = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
}
