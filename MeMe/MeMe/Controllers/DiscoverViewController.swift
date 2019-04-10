//
//  DiscoverViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class DiscoverViewController: TabViewController, NewMemeDelegate, PostNavigationDelegate {
    @IBOutlet weak var feedView: DiscoverView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedView.delegate = self
    }
    
    func addMeme(post: FeedCellData, feed:Bool) {
        feedView.addPost(post: post, feed:feed, update: true)
    }
    
    func navigateToPost(postVC: PostViewController) {
        navigationController?.pushViewController(postVC, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewMemeSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let dest = destinationNavigationController.topViewController as! GalleryViewController
            dest.delegate = self
        }
    }
    
    override func update() {
        feedView.reload()
        feedView.scrollToTop()
    }
    
}
