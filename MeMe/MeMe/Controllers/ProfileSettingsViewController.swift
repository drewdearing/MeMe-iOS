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

private let loginStoryIdentifier = "loginVCStoryIdentifier"

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
                    DispatchQueue.global(qos: .background).async {
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
        let userDocumentReference = database.collection("users").document(currentUserID)
        
        userDocumentReference.getDocument {
            (userDocumentSnapshot, error) in
            
            if let userDocumentSnapshot = userDocumentSnapshot,
                userDocumentSnapshot.exists,
                let userData = userDocumentSnapshot.data(),
                let fetchedUser = User(dictionary: userData) {
                    print("About to unfollow for user", currentUserID)
                    self.unfollowUsers(currentUser: fetchedUser)
                    print("About to delete Posts for user", currentUserID)
                    self.deleteUserPosts(currentUser: fetchedUser)
                    print("Setting username and profile Pic to default", currentUserID)
                    self.setUserToDefaultDeletedUser(currentUserID: currentUserID)
            }
        }
    }
    
    private func unfollowUsers(currentUser: User) {
        unfollowAllFollowing(currentUser: currentUser)
        removeFromAllFollowingUsers(currentUser: currentUser)
    }
    
    private func setUserToDefaultDeletedUser(currentUserID: String) {
        let defaultUsername = "Unknown"
        let defaultProfilePicURL = "https://firebasestorage.googleapis.com/v0/b/meme-d3805.appspot.com/o/profile_gDIlgji3zEYJIfVj2DBpncr9NN53.png?alt=media&token=f1b19b30-0d90-4e48-9fb8-05fa51dccd5d"
        
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
    
    private func unfollowAllFollowing(currentUser: User) {
        let usersRef = database.collection("users")
        let following = currentUser.following
        let currentUserID = authentication.currentUser?.uid
        
        DispatchQueue.global(qos: .userInteractive).async {
            for followingUser in following {
                
                let followingUserRef = usersRef.document(followingUser)
                followingUserRef.getDocument { (userDocumentSnapshot, error) in
                    
                    if let userDocumentSnapshot = userDocumentSnapshot,
                        userDocumentSnapshot.exists,
                        let userData = userDocumentSnapshot.data() {
                        
                        if var uFollowingUser = User(dictionary: userData) {
                            
                            for followerIndex in 0..<uFollowingUser.followers.count {
                                if uFollowingUser.followers[followerIndex] == currentUserID {
                                    uFollowingUser.followers.remove(at: followerIndex)
                                    
                                    followingUserRef.updateData(["followers" : uFollowingUser.followers,
                                                                 "numFollowers": uFollowingUser.followers.count]) {
                                        error in
                                        if let error = error {
                                            print("Error updating document: \(error)")
                                        } else {
                                            print("Unfollowed all following users successfully updated")
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func removeFromAllFollowingUsers(currentUser: User) {
        let usersRef = database.collection("users")
        let followers = currentUser.followers
        let currentUserID = authentication.currentUser?.uid
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            for followerUser in followers {
                
                let followerUserRef = usersRef.document(followerUser)
                followerUserRef.getDocument { (userDocumentSnapshot, error) in
                    
                    if let userDocumentSnapshot = userDocumentSnapshot,
                        userDocumentSnapshot.exists,
                        let userData = userDocumentSnapshot.data() {
                        
                        if var uFollowerUser = User(dictionary: userData) {
                            
                            for followingIndex in 0..<uFollowerUser.following.count {
                                if uFollowerUser.following[followingIndex] == currentUserID {
                                    uFollowerUser.following.remove(at: followingIndex)
                                    
                                    followerUserRef.updateData(["following" : uFollowerUser.following,
                                                                "numFollowing": uFollowerUser.following.count]) {
                                                                    error in
                                        if let error = error {
                                            print("Error updating document: \(error)")
                                        } else {
                                            print("Unfollowed all following users successfully updated")
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteUserPosts(currentUser: User) {
        let postsRef = self.database.collection("post")
        var postImageIndex: Int = currentUser.posts.count
        
        DispatchQueue.global(qos: .background).async {
            
            while postImageIndex > 0 {
                postImageIndex -= 1
                
                print("Post To Delete", currentUser.posts[postImageIndex])
                let postRef = postsRef.document(currentUser.posts[postImageIndex])
                
                postRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        
                        if let docData = document.data(),
                            let photoURL = docData["photoURL"] as? String {
                            print("photoURL", photoURL)
                            let httpsReference = self.storage.reference(forURL: photoURL)
                            httpsReference.delete(completion: { (error) in
                                if let error = error {
                                    print("Error deleting Image: \(error)")
                                } else {
                                    print("Image successfully Deleted!")
                                    postRef.delete(completion: { (error) in
                                        if let error = error {
                                            print("Error removing document: \(error)")
                                        } else {
                                            print("Document successfully removed!")
                                        }
                                    })
                                }
                            })
                        }
                    } else {
                        print("Document does not exist: \(String(describing: error))")
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
