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

protocol ProfileSettingsDelegate {
    func updateUsername(newUsername: String)
}

class ProfileViewController: UIViewController, UICollectionViewDataSource,
UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ProfileSettingsDelegate {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet var postsCollectionView: UICollectionView!
    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var navBarItem: UINavigationItem!
    
    var uid: String = Auth.auth().currentUser!.uid
    var postData:[String:PostData] = [:]
    var data:[PostData] = []
    var numFollowers:Int32 = 0
    var numFollowing:Int32 = 0
    var followed:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.layer.borderWidth = 10
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.clipsToBounds = true
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        followButton.isEnabled = false
        followersLabel.text = "0 followers"
        followingLabel.text = "following 0"
        settingsButton.isEnabled = false
        
        cache.getProfile(uid: uid) { (profile) in
            if let profile = profile {
                self.numFollowers = profile.numFollowers
                self.numFollowing = profile.numFollowing
                self.usernameLabel.text = profile.username
                self.followersLabel.text = "\(profile.numFollowers) followers"
                self.followingLabel.text = "following \(profile.numFollowing)"
                self.navBarItem.title = profile.username+"'s Profile"
                let currentUser = Auth.auth().currentUser!
                if currentUser.uid != profile.id {
                    if profile.following {
                        self.followed = true
                        self.followButton.setImage(#imageLiteral(resourceName: "heartFilled"), for: .normal)
                    }
                    self.followButton.isEnabled = true
                }
                else{
                    self.settingsButton.isEnabled = true
                }
                cache.getImage(imageURL: profile.profilePicURL, complete: { (profilePic) in
                    self.profileImageView.image = profilePic
                })
            }
        }
        
        //reloadPosts()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let postCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ProfilePostCollectionViewCell
        cache.getPost(id: data[indexPath.row].id) { (post) in
            if let post = post {
                cache.getImage(imageURL: post.photoURL, complete: { (postImage) in
                    postCollectionViewCell.postImageView.image = postImage
                })
            }
        }
        return postCollectionViewCell
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
            cache.getProfile(uid: uid) { (profile) in
                if let profile = profile {
                    postVCDestination.username = profile.username
                    cache.getPost(id: self.data[indexPath.item].id, complete: { (post) in
                        if let post = post {
                            cache.getImage(imageURL: post.photoURL, complete: { (image) in
                                postVCDestination.selectedImage = image
                                self.navigationController?.pushViewController(postVCDestination, animated: true)
                            })
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func follow(_ sender: Any) {
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
    
    func followMember() {
        let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/follow"
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&following=" + uid)
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
            urlPathBase = urlPathBase.appending("&following=" + uid)
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
