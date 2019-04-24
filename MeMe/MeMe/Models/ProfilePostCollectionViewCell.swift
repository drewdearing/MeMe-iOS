//
//  ProfilePostCollectionViewCell.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class ProfilePostCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    var postID:String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func fill(postData:PostData) {
        postID = postData.id
        cache.getPost(id: postID) { (post) in
            if let post = post {
                let imageURL = post.photoURL
                cache.getImage(imageURL: imageURL, complete: { (postImage) in
                    self.postImageView.image = postImage
                })
            }
        }
    }
    
}
