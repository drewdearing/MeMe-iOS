//
//  ProfileViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "ProfileCellIdentifier"
private let PostVCStoryboardID = "individualPost"

class ProfileViewController: UIViewController, UICollectionViewDataSource,
UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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
    var posts: [Post] = []
    var postImages: [UIImage] = []
    var postI: [PostImage] = []
    
    var followed: Bool = false
    var numFollowers:Int = 0
    var numFollowing:Int = 0
    var userID: String = ""
    var currentProfile: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        
        backgroundImageLoadingIndicator.startAnimating()
        postImagesLoadingIndicator.startAnimating()

        if(currentProfile) {
            DispatchQueue.global(qos: .userInteractive).async {
                self.fetchPosts()
            }
        
            if let currentUserProfile = getCurrentProfile() {
                usernameLabel.text = currentUserProfile.username
                followersLabel.text = String(currentUserProfile.numFollowers) + " followers"
                followingLabel.text = "following " + String(currentUserProfile.numFollowing)
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
                    self.followersLabel.text = String(document.get("numFollowers") as! Int) + " followers"
                    self.followingLabel.text = "following " + String(document.get("numFollowing") as! Int)
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
        
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Post", bundle: nil)
        if let postVCDestination = postStoryBoard.instantiateViewController(withIdentifier: PostVCStoryboardID) as? PostViewController {
            
            let row = indexPath.row
            postVCDestination.post2 = postI[row].post
            postVCDestination.postImage = postI[row].image
            if user != nil {
                postVCDestination.user = user
            }
            postVCDestination.fromProfile = true
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
                        let topText = docData["topText"] as? String,
                        let bottomText = docData["bottomText"] as? String,
                        let description = docData["description"] as? String,
                        let timestamp = docData["timestamp"] as? Firebase.Timestamp,
                        let upVotes = docData["upvotes"] as? Int,
                        let downVotes = docData["downvotes"] as? Int {
                        
                        let post = Post(userID: userID,
                                        photoURL: photoURL,
                                        topText: topText,
                                        bottomText: bottomText,
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
    
    private func fetchPostImage(post: Post, photoURL: String) {
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
                    
                    self.followersLabel.text = String(self.user!.numFollowers) + " followers"
                    self.followingLabel.text = "following " + String(self.user!.numFollowing)
                }
            }
        }
    }

    private func fetchProfileImage(currentUserProfile: Profile) {
        if let userID = Auth.auth().currentUser?.uid {
            DispatchQueue.global(qos: .userInteractive).async {
                if let profilePic = cache.getProfilePic(uid: userID) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = profilePic
                    }
                }
                else{
                    let url = URL(string: currentUserProfile.profilePicURL)
                    let data = try? Data(contentsOf: url!)
                    if let imgData = data {
                        let image = UIImage(data:imgData)
                        DispatchQueue.main.async {
                            self.profileImageView.image = image
                        }
                        cache.addProfilePic(id: userID, image: image)
                    }
                }
            }
        }
    }
    @IBAction func follow(_ sender: Any) {
        print(followed)
        if(!followed) {
            print(numFollowers)
            followed = true
            followButton.setImage(#imageLiteral(resourceName: "heartFilled"), for: .normal)
            numFollowers += 1
            followersLabel.text = String(numFollowers) + " followers"
            //updateFollowers()
        } else {
            followed = false
            followButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
            numFollowers -= 1
            followersLabel.text = String(numFollowers) + " followers"
        }
    }
    
    private func updateFollowers() {
        let followerID = Auth.auth().currentUser?.uid
        let userID = self.userID
        let ref = Firestore.firestore().collection("users").document(userID)
        ref.collection("followers").document(followerID as! String)
    }
}
