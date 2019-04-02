//
//  PostViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
    
    @IBOutlet var postImageView: UIImageView!
    @IBOutlet var userProfileImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var upVoteLabel: UILabel!
    @IBOutlet var downVoteLabel: UILabel!
    
    @IBOutlet var followingButton: UIButton!
    
    var post: Post!
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    private func setNavigationBar() {
        //        self.navigationItem.title = user.username + " Meme"
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
