//
//  HomeViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var feedView: HomeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewMemeSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let dest = destinationNavigationController.topViewController as! GalleryViewController
            dest.delegates.append(feedView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //feedView.getPosts()
    }
}
