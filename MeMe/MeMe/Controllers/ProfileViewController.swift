//
//  ProfileViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

private let ProfileSettingsSegueID = "profileSettingsIdentifier"
private let reuseIdentifier = "ProfileCellIdentifier"
private let PostVCStoryboardID = "individualPost"

protocol ProfileSettingsDelegate {
    func updateUsername(newUsername: String)
}

class ProfileViewController: TabViewController, UICollectionViewDataSource,
UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ProfileSettingsDelegate, UIScrollViewDelegate {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet var postsCollectionView: UICollectionView!
    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var navBarItem: UINavigationItem!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    
    var uid: String = Auth.auth().currentUser!.uid
    var postData:[String:PostData] = [:]
    var data:[PostData] = []
    var numFollowers:Int32 = 0
    var numFollowing:Int32 = 0
    var followed:Bool = false
    var loading = false
    var hitBottom = false
    var hitTop = false
    let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/getUserPosts"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        postsCollectionView.delegate = self
        postsCollectionView.dataSource = self
        followButton.isEnabled = false
        followersLabel.text = "0 followers"
        followingLabel.text = "following 0"
        settingsButton.isEnabled = false
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.layer.borderWidth = 10
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.clipsToBounds = true
        setProfile()
        reloadPosts(showProgress: false)
    }
    
    func setProfile(){
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
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!loading && !hitBottom && scrollView.contentOffset.y >= max(0, scrollView.contentSize.height - scrollView.frame.size.height)) {
            hitBottom = true
            hitTop = false
        }
        if (!loading && !hitTop && scrollView.contentOffset.y < 0){
            hitTop = true
            hitBottom = false
        }
        if (scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= max(0, scrollView.contentSize.height - scrollView.frame.size.height)){
            if(!loading && hitTop){
                reloadPosts(showProgress: false)
            }
            else if(!loading && hitBottom){
                loadMorePosts(showProgress: false)
            }
            hitTop = false
            hitBottom = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let postCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ProfilePostCollectionViewCell
        postCollectionViewCell.postImageView.backgroundColor = UIColor(hex: data[indexPath.row].color)
        cache.getPost(id: data[indexPath.row].id) { (post) in
            if let post = post {
                cache.getImage(imageURL: post.photoURL, complete: { (postImage) in
                    postCollectionViewCell.postImageView.image = postImage
                })
            }
        }
        updateCollectionHeight()
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    
    func updateCollectionHeight(){
        let height = self.postsCollectionView.contentSize.height
        self.heightConstraint.constant = height
        self.view.layoutIfNeeded()
    }
    
    func loadMorePosts(showProgress:Bool = true){
        loading = true
        if showProgress {
            SVProgressHUD.show(withStatus: "loading...")
        }
        getMorePosts { (feedContainer) in
            var added = 0
            for post in feedContainer.posts {
                if self.postData[post.id] == nil {
                    self.postData[post.id] = post
                    added += 1
                }
            }
            if added > 0 {
                self.updateCollection()
                DispatchQueue.main.async {
                    self.loading = false
                    if showProgress {
                        SVProgressHUD.dismiss()
                    }
                }
            }
            else {
                self.loading = false
                if showProgress {
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    func reloadPosts(showProgress:Bool = true){
        loading = true
        postData = [:]
        //data = []
        if showProgress {
            SVProgressHUD.show(withStatus: "loading...")
        }
        getPosts { (feedContainer) in
            for post in feedContainer.posts {
                self.postData[post.id] = post
            }
            self.updateCollection()
            self.loading = false
            if showProgress {
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func updateCollection() {
        DispatchQueue.main.async {
            let newData = self.sortData()
            self.data = newData
            self.postsCollectionView.reloadData()
            if self.data.count > 0 {
                self.backgroundImageView.backgroundColor = UIColor(hex: self.data[0].color)
                cache.getPost(id: self.data[0].id) { (post) in
                    if let post = post {
                        cache.getImage(imageURL: post.photoURL, complete: { (postImage) in
                            self.backgroundImageView.image = postImage
                        })
                    }
                }
            }
            else{
                self.backgroundImageView.image = nil
                self.backgroundImageView.backgroundColor = UIColor(hex: "#5397FF")
            }
        }
    }
    
    func sortData() -> [PostData] {
        return Array(self.postData.values).sorted(by: {$0.timestamp > $1.timestamp})
    }
    
    func getPosts(complete: @escaping (FeedContainer) -> Void) {
        var urlPathBase = urlPath
        urlPathBase = urlPathBase.appending("?uid=" + uid)
        let request = NSMutableURLRequest()
        request.url = URL(string: urlPathBase)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            guard let data = data else { return }
            do {
                let postContainer = try JSONDecoder().decode(FeedContainer.self, from: data)
                complete(postContainer)
            } catch let jsonErr {
                print("Error: \(jsonErr)")
            }
        }
        task.resume()
    }
    
    func getMorePosts(complete: @escaping (FeedContainer) -> Void) {
        var urlPathBase = urlPath
        urlPathBase = urlPathBase.appending("?uid=" + uid)
        if data.count > 0 {
            let post = data[data.count-1]
            var timestamp = Double(post.timestamp._seconds)
            timestamp += Double(post.timestamp._nanoseconds) * 0.000000001
            urlPathBase = urlPathBase.appending("&timestamp="+String(timestamp))
        }
        print(urlPathBase)
        let request = NSMutableURLRequest()
        request.url = URL(string: urlPathBase)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            guard let data = data else { return }
            do {
                let postContainer = try JSONDecoder().decode(FeedContainer.self, from: data)
                complete(postContainer)
            } catch let jsonErr {
                print("Error: \(jsonErr)")
            }
        }
        task.resume()
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
    
    func scrollToTop() {
        if data.count > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: true)
        }
    }
    
    override func update() {
        if !loading {
            reloadPosts(showProgress: false)
        }
        scrollToTop()
        setProfile()
    }
    
    func updateUsername(newUsername: String) {
        usernameLabel.text = newUsername
        self.navBarItem.title = newUsername+"'s Profile"
    }
}
