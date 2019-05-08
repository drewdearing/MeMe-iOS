//
//  DiscoverViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore

public let SearchUserCellID = "SearchUserCellID"

class DiscoverViewController: TabViewController, NewMemeDelegate, FeedViewDelegate, ImagePickerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var feedView: DiscoverView!
    var imagePicker:ImagePicker!
    var selectedImage:UIImage?
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchUserTableView: UITableView!
    
    var database: Firestore = Firestore.firestore()
    var storage: Storage = Storage.storage()
    
    var allUsers: [User] = []
    var allProfileImage: [User: UIImage] = [:]
    var allUsersID: [User: String] = [:]
    
    var searchUsernames: [String] = []
    var users: [User] = []
    
    private var isFetching: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedView.delegate = self
        self.imagePicker = ImagePicker(presentationController: self, delegate: self, editAllowed: false)
        
        searchUserTableView.delegate = self
        searchUserTableView.dataSource = self
        searchBar.delegate = self
        searchUserTableView.isHidden = true
        
        fetchAllUsers()
    }
    
    func addMeme(post: PostData) {
        feedView.addPost(post: post)
    }
    
    func navigateToPost(postVC: PostViewController) {
        navigationController?.pushViewController(postVC, animated: true)
    }
    
    func navigateToProfile(profileVC: ProfileViewController) {
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @IBAction func selectImage(_ sender: Any) {
        self.imagePicker.present(from: self.view)
    }
    
    func didSelect(image: UIImage?) {
        if let image = image {
            selectedImage = image
            performSegue(withIdentifier: "NewMemeSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewMemeSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let dest = destinationNavigationController.topViewController as! EditMemeViewController
            dest.selectedImage = selectedImage
            dest.delegate = self
        }
    }
    
    override func update() {
        if !feedView.loading {
            feedView.reloadPosts()
        }
        feedView.scrollToTop()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchUserCellID, for: indexPath as IndexPath) as? SearchUserTableViewCell
        let row = indexPath.row
        let user = users[row]
        cell?.usernameLabel.text = user.username
        cell?.profileImageView.image = allProfileImage[user]
        
        return cell!
    }
    
    func fetchAllUsers() {
        isFetching = true
        
        allUsers.removeAll()
        allProfileImage.removeAll()
        allUsersID.removeAll()
        
        DispatchQueue.global(qos: .userInteractive).async {
            _ = self.database.collection("users").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        if let fetchedUser = User(dictionary: document.data()) {
                            self.allUsers.append(fetchedUser)
                            self.allUsersID.updateValue(document.documentID, forKey: fetchedUser)
                        }
                    }
                    DispatchQueue.main.async {
                        self.isFetching = false
                        self.fetchProfilePictures();
                    }
                }
            }
        }
    }
    
    private func fetchProfilePictures() {
        for user in self.allUsers {
            DispatchQueue.global(qos: .userInteractive).async {
                if !self.allProfileImage.keys.contains(user) {
                    let url = URL(string: user.profilePicture)
                    let data = try? Data(contentsOf: url!)
                    if let imageData = data {
                        if let image = UIImage(data: imageData) {
                            DispatchQueue.main.async {
                                self.allProfileImage.updateValue(image, forKey: user)
                                self.searchUserTableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
        
        self.isFetching = false;
    }
}

extension DiscoverViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var usernames: [String] = []
        if searchText.isEmpty {
            searchUserTableView.isHidden = true
            return
        } else {
            searchUserTableView.isHidden = false
        }
        
        for user in allUsers  {
            usernames.append(user.username)
        }
        
        searchUsernames = usernames.filter({$0.lowercased().prefix(searchText.count) == searchText.lowercased()})
        
        users.removeAll()
        
        for index in 0 ..< allUsers.count {
            for jndex in 0 ..< searchUsernames.count {
                if allUsers[index].username == searchUsernames[jndex] &&
                    allUsers[index].username != Auth.auth().currentUser!.uid &&
                    allUsers[index].profilePicture != "https://cnam.ca/wp-content/uploads/2018/06/default-profile.gif" {
                    users.append(allUsers[index])
                }
            }
        }
        searchUserTableView.reloadData()
        if !isFetching {
            fetchAllUsers()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text?.removeAll(keepingCapacity: true)
        searchUserTableView.reloadData()
        searchUserTableView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = users[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        if let controller = storyboard.instantiateViewController(withIdentifier: "profileView") as? ProfileViewController {
            // set data to controller
            if let uid = allUsersID[current] {
                controller.uid = uid
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}
