//
//  EditMemeViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class EditMemeViewController: UIViewController {
    
    @IBOutlet weak var memeImageView: UIImageView!
    var selectedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if selectedImage != nil {
            memeImageView.image = selectedImage
        }
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
