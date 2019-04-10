//
//  DiscoverViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class DiscoverViewController: TabViewController, NewMemeDelegate, PostNavigationDelegate, ImagePickerDelegate {
    
    @IBOutlet weak var feedView: DiscoverView!
    var imagePicker:ImagePicker!
    var selectedImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedView.delegate = self
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    func addMeme(post: FeedCellData, feed:Bool) {
        feedView.addPost(post: post, feed:feed, update: true)
    }
    
    func navigateToPost(postVC: PostViewController) {
        navigationController?.pushViewController(postVC, animated: true)
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
            let dest = segue.destination as! EditMemeViewController
            dest.selectedImage = selectedImage
            dest.delegate = self
        }
    }
    
    override func update() {
        feedView.reload()
        feedView.scrollToTop()
    }
    
}
