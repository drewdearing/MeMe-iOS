//
//  DiscoverViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class DiscoverViewController: TabViewController, NewMemeDelegate, FeedViewDelegate, ImagePickerDelegate {
    
    @IBOutlet weak var feedView: DiscoverView!
    var imagePicker:ImagePicker!
    var selectedImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedView.delegate = self
        self.imagePicker = ImagePicker(presentationController: self, delegate: self, editAllowed: false)
    }
    
    func addMeme(post: PostData) {
        feedView.addPost(post: post)
    }
    
    func navigateToPost(postVC: PostViewController) {
        navigationController?.pushViewController(postVC, animated: true)
    }
    
    func navigateToProfile(profileVC: ProfileViewController) {
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @IBAction func selectImage(_ sender: Any) {
        self.imagePicker.present(from: self.view)
    }
    
    func didSelect(image: UIImage?) {
        selectedImage = image
        performSegue(withIdentifier: "NewMemeSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewMemeSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let dest = destinationNavigationController.topViewController as! EditMemeViewController
            dest.selectedImage = selectedImage
            dest.delegate = self
        }
    }
    
    override func update() {
        if !feedView.loading {
            feedView.reloadPosts()
        }
        feedView.scrollToTop()
    }
    
}
