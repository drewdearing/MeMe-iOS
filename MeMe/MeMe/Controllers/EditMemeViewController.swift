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
    func addMeme(post: PostData)
}

class EditMemeViewController: UIViewController, EditToolsDelegate, BrushSettingsDelegate, TextSettingsDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet var textColorView: UIView!
    @IBOutlet var brushColorView: UIView!
    @IBOutlet var brushButton: UIButton!
    @IBOutlet var textButton: UIButton!
    var desc: String = ""
    var lastPoint = CGPoint.zero
    var hue: CGFloat = 0
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var brushWidth: CGFloat = 10.0
    var textSize:CGFloat = 24
    var textHue:CGFloat = 0
    var draw = true
    var originalSize:CGSize!
    var text:String = ""
    var swiped = false
    var selectedImage: UIImage!
    var tempImage:UIImage!
    var delegate:NewMemeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedImage != nil {
            memeImageView.image = selectedImage
            tempImage = selectedImage
            originalSize = selectedImage.size
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
        tempImage = memeImageView.image!
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
    
    func textToImage(drawText text: String, atPoint point: CGPoint){
        tempImage = memeImageView.image!
        let textFont = UIFont(name: "Helvetica Bold", size: textSize)!
        UIGraphicsBeginImageContext(memeImageView.frame.size)
        
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
        
        memeImageView.image?.draw(in: CGRect(x: 0, y: y, width: width, height: height))
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: point)
        
        let textColor = UIColor(hue: textHue, saturation: 1, brightness: 1, alpha: 1)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        
        let rect = CGRect(origin: point, size: memeImageView.image!.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        context?.addRect(rect)
        
        memeImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if draw {
            if let touch = touches.first {
                let currentPoint = touch.location(in: memeImageView)
                drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
                lastPoint = currentPoint
            }
        }
        else{
            if let touch = touches.first {
                memeImageView.image = tempImage
                let currentPoint = touch.location(in: memeImageView)
                textToImage(drawText: text, atPoint: currentPoint)
                lastPoint = currentPoint
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if draw {
            if !swiped {
                drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
            }
        }
        else{
            if let touch = touches.first {
                let currentPoint = touch.location(in: memeImageView)
                textToImage(drawText: text, atPoint: currentPoint)
            }
        }
    }
    
    func updateText(text: String, textSize: Float, textHue: Float) {
        self.textHue = CGFloat(textHue)
        self.textSize = CGFloat(textSize)
        self.text = text
        textColorView.backgroundColor = UIColor(hue: CGFloat(textHue), saturation: 1, brightness: 1, alpha: 1)
    }
    
    func updateDesc(desc: String) {
        self.desc = desc
    }
    
    func updateBrush(size: Float, hue: Float, red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.brushWidth = CGFloat(size)
        self.hue = CGFloat(hue)
        self.red = red
        self.green = green
        self.blue = blue
        brushColorView.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func addMeme(post: PostData) {
        delegate?.addMeme(post: post)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditToolsSegue" {
            let dest = segue.destination as! EditToolsViewController
            dest.delegate = self
            dest.desc = desc
            dest.selectedImage = memeImageView.image
            dest.originalSize = originalSize
        }
        if segue.identifier == "BrushSettingsSegue" {
            let dest = segue.destination as! BrushSettingsViewController
            dest.delegate = self
            dest.blue = Float(blue)
            dest.red = Float(red)
            dest.green = Float(green)
            dest.brush = Float(brushWidth)
            dest.hue = Float(hue)
            dest.modalPresentationStyle = .popover
            let width = view.frame.width - (36+16+16)
            dest.preferredContentSize = CGSize(width: width, height: 100)
            let presentationController = dest.presentationController as! UIPopoverPresentationController
            presentationController.delegate = self
            presentationController.sourceView = brushButton
            presentationController.sourceRect = brushButton.bounds
            presentationController.permittedArrowDirections = [.up, .right]
        }
        if segue.identifier == "TextSettingsSegue" {
            let dest = segue.destination as! TextSettingsViewController
            dest.delegate = self
            dest.text = text
            dest.textHue = Float(textHue)
            dest.textSize = Float(textSize)
            dest.modalPresentationStyle = .popover
            let width = view.frame.width - (36+16+16)
            dest.preferredContentSize = CGSize(width: width, height: 201)
            let presentationController = dest.presentationController as! UIPopoverPresentationController
            presentationController.delegate = self
            presentationController.sourceView = textButton
            presentationController.sourceRect = textButton.bounds
            presentationController.permittedArrowDirections = [.up, .right]
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    @IBAction func brushTool(_ sender: Any) {
        if draw {
            performSegue(withIdentifier: "BrushSettingsSegue", sender: self)
        }
        else{
            draw = true
            textButton.backgroundColor = .lightGray
            brushButton.backgroundColor = nil
        }
    }
    
    @IBAction func textTool(_ sender: Any) {
        if !draw {
            performSegue(withIdentifier: "TextSettingsSegue", sender: self)
        }
        else{
            draw = false
            brushButton.backgroundColor = .lightGray
            textButton.backgroundColor = nil
        }
    }
}
