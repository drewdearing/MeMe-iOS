//
//  TextSettingsViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 5/6/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class TextSettingsViewController: UIViewController {
    @IBOutlet var textField: UITextField!
    @IBOutlet var sizeSlider: UISlider!
    @IBOutlet var colorSlider: UISlider!
    @IBOutlet var imageView: UIImageView!
    var textColor:UIColor!
    var textSize:Float!
    var text:String!
    var textHue:Float!
    var delegate:TextSettingsDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.text = text
        sizeSlider.maximumValue = 70.0
        sizeSlider.minimumValue = 10.0
        sizeSlider.setValue(textSize, animated: false)
        colorSlider.setValue(textHue, animated: false)
        textColor = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        colorSlider.thumbTintColor = textColor
        setTextPreview()
    }
    
    func setTextPreview(){
        imageView.image = nil
        let textFont = UIFont(name: "Helvetica Bold", size: CGFloat(sizeSlider!.value))!
        UIGraphicsBeginImageContext(imageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2))
        
        let textColor = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: imageView.frame.size)
        textField.text?.draw(in: rect, withAttributes: textFontAttributes)
        context?.addRect(rect)
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        delegate.updateText(text: textField.text!, textSize: sizeSlider.value, textHue: colorSlider.value)
    }
    
    @IBAction func textChanged(_ sender: Any) {
        setTextPreview()
    }
    
    @IBAction func sizeSliderChanged(_ sender: Any) {
        setTextPreview()
    }
    
    @IBAction func colorSliderChanged(_ sender: Any) {
        colorSlider.thumbTintColor = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        setTextPreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate.updateText(text: textField.text!, textSize: sizeSlider.value, textHue: colorSlider.value)
    }

}
