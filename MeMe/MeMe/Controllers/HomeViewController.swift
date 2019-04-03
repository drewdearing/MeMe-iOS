//
//  HomeViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, NewMemeDelegate {
    
    @IBOutlet weak var feedView: HomeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if feedView.loaded {
            feedView.getPosts()
        }
    }
    
    func addMeme(post: FeedCellData) {
        feedView.addPost(post: post)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewMemeSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let dest = destinationNavigationController.topViewController as! GalleryViewController
            dest.delegate = self
        }
    }
    
}
