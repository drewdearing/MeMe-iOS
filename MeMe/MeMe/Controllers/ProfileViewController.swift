//
//  ProfileViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

private let ProfileSettingsSegueID = "profileSettingsIdentifier"
private let reuseIdentifier = "ProfileCellIdentifier"
private let PostVCStoryboardID = "individualPost"

protocol UsernameUpdatedDelegate {
    func updateUsername(newUsername: String)
}

class ProfileViewController: UIViewController, UICollectionViewDataSource,
UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UsernameUpdatedDelegate {
    @IBOutlet weak var backgroundImageLoadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var postImagesLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet var postsCollectionView: UICollectionView!
    
    var user: User? = nil
    var posts: [MyPost] = []
    var postImages: [UIImage] = []
    var postI: [PostImage] = []
    
    var followed: Bool = false
    var numFollowers:Int = 0
    var numFollowing:Int = 0
    var userID: String = Auth.auth().currentUser!.uid
    var currentProfile: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        
        backgroundImageLoadingIndicator.startAnimating()
        postImagesLoadingIndicator.startAnimating()
        followButton.isEnabled = false
        followersLabel.text = "Followed"
        
        if let currentUser = Auth.auth().currentUser{
            if userID != currentUser.uid {
                Firestore.firestore().collection("users").document(userID).collection("followers").document(currentUser.uid).getDocument { (followDoc, err) in
                    if let doc = followDoc {
                        if doc.exists {
                            self.followButton.isEnabled = true
                            self.followButton.setImage(#imageLiteral(resourceName: "heartFilled"), for: .normal)
                            self.followed = true
                        }
                        else{
                            self.followButton.isEnabled = true
                        }
                    }
                }
            }
        }

        if(currentProfile) {
            DispatchQueue.global(qos: .userInteractive).async {
                self.fetchPosts()
            }
        
            if let currentUserProfile = getCurrentProfile() {
                usernameLabel.text = currentUserProfile.username
                //followersLabel.text = String(currentUserProfile.numFollowers) + " followers"
                //followingLabel.text = "following " + String(currentUserProfile.numFollowing)
                fetchProfileImage(currentUserProfile: currentUserProfile)
            }
        } else {
            DispatchQueue.global(qos: .userInteractive).async {
                self.fetchUser(userID: self.userID)
            }
            let ref = Firestore.firestore().collection("users").document(userID)
            ref.getDocument { (document, error) in
                if let document = document, document.exists {
                    self.usernameLabel.text = (document.get("username") as! String)
                    //self.followersLabel.text = String(document.get("numFollowers") as! Int) + " followers"
                    //self.followingLabel.text = "following " + String(document.get("numFollowing") as! Int)
                    let pic = document.get("profilePicURL")
                    let url = URL(string: pic as! String)
                    let data = try? Data(contentsOf: url!)
                    if let imageData = data {
                        let image = UIImage(data: imageData)
                        self.profileImageView.image = image
                    }
                }else{
                    print("Document does not exist")
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postI.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let postCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ProfilePostCollectionViewCell
        
        // Configure the cell
        let row = indexPath.row
        
        postCollectionViewCell?.postImageView.image = postI[row].image
        
        return postCollectionViewCell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3 - 1
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Add code here to
        
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "ProfilePreviewStoryboard", bundle: nil)
        if let postVCDestination = postStoryBoard.instantiateViewController(withIdentifier: "previewVC") as? ProfilePreviewViewController {
            let row = indexPath.row
            postVCDestination.selectedImage = postI[row].image
            if user != nil {
                postVCDestination.username = user?.username
            }
            self.navigationController?.pushViewController(postVCDestination, animated: true)
        }
    }
 
    
    func fetchPosts() {
        if let userID = Auth.auth().currentUser?.uid {
            fetchUser(userID: userID)
        }
    }
    
    private func fetchUser(userID: String) {
        var fetchedUser: User!
        let ref = Firestore.firestore().collection("users").document(userID)
        
        ref.getDocument {
            (userDocumentSnapshot, error) in
            
            if let userDocumentSnapshot = userDocumentSnapshot,
                userDocumentSnapshot.exists,
                let userData = userDocumentSnapshot.data() {
                
                fetchedUser = User(dictionary: userData)
                self.user = fetchedUser
                self.fetchUserPosts(user: fetchedUser)
            }
        }
    }
    
    private func fetchUserPosts(user: User) {
        let postsRef = Firestore.firestore().collection("post")
        var postIndex: Int = user.posts.count
        
        while postIndex > 0 {
            postIndex -= 1
            
            let postRef = postsRef.document(user.posts[postIndex])
            
            postRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    
                    if let docData = document.data(),
                        let userID = docData["uid"] as? String,
                        let photoURL = docData["photoURL"] as? String,
                        let description = docData["description"] as? String,
                        let timestamp = docData["timestamp"] as? Firebase.Timestamp,
                        let upVotes = docData["upvotes"] as? Int,
                        let downVotes = docData["downvotes"] as? Int {
                        
                        let post = MyPost(userID: userID,
                                        photoURL: photoURL,
                                        description: description,
                                        timeStamp: timestamp,
                                        upVotes: upVotes,
                                        downVotes: downVotes)
                        self.posts.append(post)
                        self.fetchPostImage(post: post, photoURL: post.photoURL)
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
        
        if user.posts.isEmpty {
            DispatchQueue.main.async {
                if self.postI.count == self.posts.count {
                    self.backgroundImageLoadingIndicator.stopAnimating()
                    self.backgroundImageLoadingIndicator.alpha = 0
                    self.postImagesLoadingIndicator.stopAnimating()
                    self.postImagesLoadingIndicator.alpha = 0
                }
            }
        }
    }
    
    private func fetchPostImage(post: MyPost, photoURL: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            let url = URL(string: photoURL)
            let data = try? Data(contentsOf: url!)
            if let imgData = data {
                self.postI.append(PostImage(post: post, image: UIImage(data:imgData)!))
                
                DispatchQueue.main.async {
                    self.postI.sort()
                    
                    if self.postI.count == self.posts.count {
                        self.fetchBackgroundImage(photoURL: (self.postI.first?.post.photoURL)!)
                        self.postsCollectionView.reloadData()
                        self.postImagesLoadingIndicator.stopAnimating()
                        self.postImagesLoadingIndicator.alpha = 0
                        self.posts.removeAll()
                    }
                }
            }
        }
    }
    
    private func fetchBackgroundImage(photoURL: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            let url = URL(string: photoURL)
            let data = try? Data(contentsOf: url!)
            if let imgData = data {
                
                DispatchQueue.main.async {
                    self.backgroundImageLoadingIndicator.stopAnimating()
                    self.backgroundImageLoadingIndicator.alpha = 0
                    self.backgroundImageView.image = UIImage(data:imgData)!
                    
                    //self.followersLabel.text = String(self.user!.numFollowers) + " followers"
                    //self.followingLabel.text = "following " + String(self.user!.numFollowing)
                }
            }
        }
    }

    private func fetchProfileImage(currentUserProfile: CurrentProfile) {
        cache.getImage(imageURL: currentUserProfile.profilePicURL) { (image) in
            if let image = image {
                self.profileImageView.image = image
            }
        }
    }
    
    @IBAction func follow(_ sender: Any) {
        if let currentUser = Auth.auth().currentUser {
            if !followed {
                followMember()
                followButton.setImage(#imageLiteral(resourceName: "heartFilled"), for: .normal)
                followersLabel.text = "Followed"
                followed = true
            }
            else{
                unfollowMember()
                followButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
                followersLabel.text = "Follow"
                followed = false
            }
        }
    }
    
    func followMember() {
        let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/follow"
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&following=" + userID)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in     }
            task.resume()
        }
    }
    
    func unfollowMember() {
        let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/unfollow"
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&following=" + userID)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in     }
            task.resume()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ProfileSettingsSegueID {
            let destination = segue.destination
            
            (destination as? ProfileSettingsViewController)?.delegate = self
        }
    }
    
    func updateUsername(newUsername: String) {
        usernameLabel.text = newUsername
        // Update to cache here...
    }
}
