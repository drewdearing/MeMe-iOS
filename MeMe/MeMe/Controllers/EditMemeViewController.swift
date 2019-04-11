//
//  EditMemeViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SVProgressHUD

protocol NewMemeDelegate {
    func addMeme(post: FeedCellData, feed:Bool)
}

class EditMemeViewController: UIViewController, EditToolsDelegate {
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    var desc: String = ""
    var lastPoint = CGPoint.zero
    var hue: CGFloat = 0
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var brushWidth: CGFloat = 10.0
    var swiped = false
    
    
    var selectedImage: UIImage!
    var delegate:NewMemeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedImage != nil {
            memeImageView.image = selectedImage
        }
        let color = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
        var alpha:CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: memeImageView)
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        var width = memeImageView.frame.width
        var height = memeImageView.frame.height
        
        let mW = width / memeImageView.image!.size.width
        let mH = height / memeImageView.image!.size.height
        
        if( mH < mW ) {
            width = height / memeImageView.image!.size.height * memeImageView.image!.size.width
        }
        else if( mW < mH ) {
            height = width / memeImageView.image!.size.width * memeImageView.image!.size.height
        }

        let y = (memeImageView.frame.height - height) / 2
        
        UIGraphicsBeginImageContext(memeImageView.frame.size)
        memeImageView.image?.draw(in: CGRect(x: 0, y: y, width: width, height: height))
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(red: red, green: green, blue: blue, alpha: 1)
        context?.setBlendMode(.normal)
        
        context?.strokePath()
        memeImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: memeImageView)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        }
    }
    
    func updateTools(size: Float, hue: Float, red: CGFloat, green: CGFloat, blue: CGFloat, desc: String) {
        self.brushWidth = CGFloat(size)
        self.hue = CGFloat(hue)
        self.red = red
        self.green = green
        self.blue = blue
        self.desc = desc
    }
    
    func addMeme(post: FeedCellData, feed: Bool) {
        delegate?.addMeme(post: post, feed: feed)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditToolsSegue" {
            let dest = segue.destination as! EditToolsViewController
            dest.delegate = self
            dest.blue = Float(blue)
            dest.red = Float(red)
            dest.green = Float(green)
            dest.brush = Float(brushWidth)
            dest.desc = desc
            dest.hue = Float(hue)
            dest.selectedImage = memeImageView.image
        }
    }
    
}
