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

protocol memberDelegate {
    func addMember(name: String, cell: PotentialUserTableViewCell)
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
    
    class Container {
        let member: String
        let image: UIImage
        
        let id: String
        init (member: String, image: UIImage, id: String) {
            self.member = member
            self.image = image
            self.id = id
        }
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
                                self.potentialMembers.append(Container(member: name as! String, image: image as! UIImage, id: id as! String))
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
        cell?.usernameLable.text = currentPotentialMembers[indexPath.row].member
        cell?.userProfileImageView.image = currentPotentialMembers[indexPath.row].image
        
        cell?.id = currentPotentialMembers[indexPath.row].id
        //cell?.userProfileImageView.image = UIImage.init(named: "checkmark")
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
        let cellname = currentPotentialMembers[indexPath.row].member
        
        let currentCell = potentialMembersTableView.cellForRow(at: indexPath) as! PotentialUserTableViewCell
        
        if (delegate != nil) {
            //group name you want to add user in
            print(groupname)
            let userid = currentCell.id
            
            let name = currentCell.usernameLable.text

            let ref_group = Firestore.firestore().collection("groups").document(groupddocid).collection("usersInGroup").document(userid).setData([
                "username": name
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
            
            
            
            
            currentCell.addlabel.adjustsFontSizeToFitWidth = true
            currentCell.addlabel.text = "Added!"
            currentCell.addlabel.isHidden = false
            delegate?.addMember(name: cellname, cell: currentCell)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
}
