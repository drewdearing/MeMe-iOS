//
//  ProfileSettingsViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/2/19.
//  Copyright © 2019 meme. All rights reserved.
//
import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestore

private let loginStoryIdentifier = "loginVC"

class ProfileSettingsViewController: UIViewController {
    var database: Firestore!
    var storage: Storage!
    var authentication: Auth!
    
    var user: User!
    
    var delegate: ProfileSettingsDelegate!
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    private var usernameText: String!
    private var emailText: String!
    private var passwordText: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        database = Firestore.firestore()
        storage = Storage.storage()
        authentication = Auth.auth()
        setNavigationBarItems()
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.fetchCurrentUser()
        }
    }
    
    private func setNavigationBarItems() {
        self.navigationItem.title = "Profile Settings"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(ProfileSettingsViewController.saveProfileEdits))
    }
    
    @IBAction func onClickLogout(_ sender: Any) {
        try! Auth.auth().signOut()
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("username", user.uid)
                // user is signed in so don't do anything
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "loginVC")
                self.present(controller, animated: true, completion: nil)
                Auth.auth().removeStateDidChangeListener(auth)
            }
        }

    }
    
    
    @objc func saveProfileEdits() {
        
        Auth.auth().signIn(withEmail: email.text!, password: password.text!) { [weak self] user, error in
            guard let strongSelf = self else { return }
            
            if let user = user {
                if let currentUserID = self!.authentication.currentUser?.uid {
                    print("About to delete", currentUserID)
                    self!.statusLabel.text = "Updating Username"
                    self?.username.isUserInteractionEnabled = false
                    self?.password.isUserInteractionEnabled = false
                    self!.navigationItem.rightBarButtonItem?.isEnabled = false
                    
                    if (self?.username.text?.isEmpty)!  {
                        self!.statusLabel.text = "Empty Text is not valid for a Username"
                        self?.username.isUserInteractionEnabled = true
                        self?.password.isUserInteractionEnabled = true
                    } else if self?.username.text == self?.usernameText {
                        self!.statusLabel.text = "Same Username"
                        self?.username.isUserInteractionEnabled = true
                        self?.password.isUserInteractionEnabled = true
                    } else {
                        DispatchQueue.main.async {
                            self!.updateUsername(newUsername: (self?.username.text)!, currentUserID: currentUserID)
                            self!.statusLabel.text = "Username Updated"
                            self?.username.isUserInteractionEnabled = true
                            self?.password.isUserInteractionEnabled = true
                            
                            if self!.delegate != nil {
                                self!.delegate.updateUsername(newUsername: (self?.username.text)!)
                            }
                        }
                    }
                }
            } else {
                self!.statusLabel.text = "Password not valid to Update Username"
            }
        }
    }
    
    
    @IBAction func deleteAccount(_ sender: Any) {
        
        Auth.auth().signIn(withEmail: email.text!, password: password.text!) { [weak self] user, error in
            guard let strongSelf = self else { return }
            
            if let user = user {
                if let currentUserID = self!.authentication.currentUser?.uid {
                    print("About to delete", currentUserID)
                    self!.statusLabel.text = "Deleting Acount..."
                    self?.username.isUserInteractionEnabled = false
                    self?.password.isUserInteractionEnabled = false
                    self!.navigationItem.rightBarButtonItem?.isEnabled = false
                    DispatchQueue.global(qos: .userInteractive).async {
                        self!.deleteUser(currentUserID: currentUserID)
                        DispatchQueue.main.async {
                            let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            if let loginVCDestination = mainStoryBoard.instantiateViewController(withIdentifier: loginStoryIdentifier) as? LoginViewController {
                                
                                let navController = UINavigationController(rootViewController: loginVCDestination)
                                self!.present(navController, animated: true, completion: nil)
                            }
                        }
                    }
                }
            } else {
                self!.statusLabel.text = "Password not valid to Delete Account"
            }
        }
    }
    
    private func updateUsername(newUsername: String, currentUserID: String) {
        let userDocumentReference = database.collection("users").document(currentUserID)
        
        userDocumentReference.updateData(["username" : newUsername]) { err in
            if let err = err {
                print("Error updating username to user document: \(err)")
            } else {
                print("Document successfully updated for new username")
            }
        }
    }
    
    private func deleteUser(currentUserID: String) {
        self.unfollowUsers(currentUserID: currentUserID)
        self.deleteUserPosts(currentUserID: currentUserID)
        self.setUserToDefaultDeletedUser(currentUserID: currentUserID)
    }
    
    private func unfollowUsers(currentUserID: String) {
        unfollowAllFollowing(currentUserID: currentUserID)
        removeFromAllFollowingUsers(currentUserID: currentUserID)
    }
    
    private func setUserToDefaultDeletedUser(currentUserID: String) {
        let defaultUsername = "Unknown"
        let defaultProfilePicURL = "https://cnam.ca/wp-content/uploads/2018/06/default-profile.gif"
        
        DispatchQueue.global(qos: .background).async {

            let userDocumentReference = self.database.collection("users").document(currentUserID)
            
            userDocumentReference.updateData(["username" : defaultUsername,
                                              "profilePicURL" : defaultProfilePicURL]) { err in
                if let err = err {
                    print("Error updating username & profilePic in user document: \(err)")
                } else {
                    print("Document successfully updated for new username")
                }
            }
        }
    }
    
    private func unfollowAllFollowing(currentUserID: String) {
        let usersRef = database.collection("users")
        let currentUserDocRef = usersRef.document(currentUserID)
        var following: [String] = []
        
        // Unfollow by deleting the to be deleted user
        DispatchQueue.global(qos: .userInteractive).async {
            currentUserDocRef.collection("following").getDocuments(completion: { (userDocumentSnapshot, error0) in
                
                if let error0 = error0 {
                    print("Error getting following documents: \(error0)")
                } else {
                    for document in userDocumentSnapshot!.documents {
                        following.append(document.documentID)
                    }
                    
                    for id in following {
                        usersRef.document(id).collection("followers").document(currentUserID).delete() { deleteError in
                            if let deleteError = deleteError {
                                print("Error removing document: \(deleteError)")
                            } else {
                                print("Deleting User Document successfully removed from follower!")
                            }
                        }
                    }
                    
                    // delete following documents and set numbers correctly
                    for id in following {
                        currentUserDocRef.collection("following").document(id).delete() { deleteError in
                            if let deleteError = deleteError {
                                print("Error removing document: \(deleteError)")
                            } else {
                                print("Deleting User Document successfully removed from follower!")
                            }
                        }
                    }
                    
                    currentUserDocRef.updateData(["numFollowing" : 0])
                    
                    // Setting Following's new Num
                    var numFollowers = 0
                    
                    for id in following {
                        usersRef.document(id).collection("followers").getDocuments(completion: { (userDocumentSnapshot, error) in
                            if let error = error {
                                print("Error getting following documents: \(error)")
                            } else {
                                numFollowers = (userDocumentSnapshot?.count)!
                                
                                usersRef.document(id).updateData(["numFollowers" : numFollowers]) { err in
                                    if let err = err {
                                        print("Error updating followers \(err)")
                                    } else {
                                        print("Document successfully updated for new followers num")
                                    }
                                }
                                
                                numFollowers = 0
                            }
                        })
                    }
                }
            })
        }
    }
    
    private func removeFromAllFollowingUsers(currentUserID: String) {
        let usersRef = database.collection("users")
        let currentUserDocRef = usersRef.document(currentUserID)
        var followers: [String] = []
        
        // Unfollow by deleting the to be deleted user
        DispatchQueue.global(qos: .userInteractive).async {
            currentUserDocRef.collection("followers").getDocuments(completion: { (userDocumentSnapshot, error0) in
                
                if let error0 = error0 {
                    print("Error getting following documents: \(error0)")
                } else {
                    for document in userDocumentSnapshot!.documents {
                        followers.append(document.documentID)
                    }
                    
                    for id in followers {
                        usersRef.document(id).collection("following").document(currentUserID).delete() { deleteError in
                            if let deleteError = deleteError {
                                print("Error removing document: \(deleteError)")
                            } else {
                                print("Deleting User Document successfully removed from follower!")
                            }
                        }
                    }
                    
                    // delete following documents and set numbers correctly
                    for id in followers {
                        currentUserDocRef.collection("followers").document(id).delete() { deleteError in
                            if let deleteError = deleteError {
                                print("Error removing document: \(deleteError)")
                            } else {
                                print("Deleting User Document successfully removed from follower!")
                            }
                        }
                    }
                    currentUserDocRef.updateData(["numFollowers" : 0])

                    // Setting Following's new Num
                    var numFollowing = 0
                    
                    for id in followers {
                        usersRef.document(id).collection("following").getDocuments(completion: { (userDocumentSnapshot, error) in
                            if let error = error {
                                print("Error getting following documents: \(error)")
                            } else {
                                numFollowing = (userDocumentSnapshot?.count)!
                                
                                usersRef.document(id).updateData(["numFollowing" : numFollowing]) { err in
                                    if let err = err {
                                        print("Error updating followers \(err)")
                                    } else {
                                        print("Document successfully updated for new followers num")
                                    }
                                }
                            
                                numFollowing = 0
                            }
                        })
                    }
                }
            })
        }
    }
    
    private func deleteUserPosts(currentUserID: String) {
        let postsRef = self.database.collection("post")
        let usersRef = database.collection("users").document(currentUserID)
        var posts: [String] = []
        
        DispatchQueue.global(qos: .userInteractive).async {
            usersRef.collection("posts").getDocuments { (postsQuerySnapshot, error) in
                if let error = error {
                    print("Error getting following documents: \(error)")
                } else {
                    for document in postsQuerySnapshot!.documents {
                        posts.append(document.documentID)
                    }
                    
                    DispatchQueue.main.async {
                        DispatchQueue.global(qos: .userInteractive).async {
                            for id in posts {
                                postsRef.document(id).delete() { deleteError in
                                    if let deleteError = deleteError {
                                        print("Error removing document: \(deleteError)")
                                    } else {
                                        print("Deleting post!")
                                    }
                                }
                                
                                usersRef.collection("posts").document(id).delete() { deleteError in
                                    if let deleteError = deleteError {
                                        print("Error removing document: \(deleteError)")
                                    } else {
                                        print("Deleting Post0!")
                                    }
                                }
                            }
                            
                            let user = Auth.auth().currentUser
                            user?.delete { error in
                                if let error = error {
                                    // An error happened.
                                    print("Error deleting user: \(error)")
                                } else {
                                    // Account deleted.
                                    print("deleted User successfully!")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchCurrentUser() {
        if let userID = authentication.currentUser?.uid {
            fetchUser(userID: userID)
        }
    }
    
    private func fetchUser(userID: String) {
        var fetchedUser: User!
        
        let userDocumentReference = database.collection("users").document(userID)
        
        userDocumentReference.getDocument {
            (userDocumentSnapshot, error) in
            
            if let userDocumentSnapshot = userDocumentSnapshot,
                userDocumentSnapshot.exists,
                let userData = userDocumentSnapshot.data() {
                
                fetchedUser = User(dictionary: userData)
                
                DispatchQueue.main.async {
                    // update views with text
                    self.usernameText = fetchedUser.username
                    self.emailText = fetchedUser.email
                    self.username.insertText(self.usernameText)
                    self.email.insertText(self.emailText)
                    
                    self.email.isUserInteractionEnabled = false
                }
            }
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
