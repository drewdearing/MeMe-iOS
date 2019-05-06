//
//  BrushSettingsViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 5/6/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class BrushSettingsViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var sizeSlider: UISlider!
    @IBOutlet var colorSlider: UISlider!
    var red:Float!
    var blue:Float!
    var green:Float!
    var brush:Float!
    var hue:Float!
    var color:UIColor!
    var delegate:BrushSettingsDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sizeSlider.maximumValue = 50.0
        sizeSlider.minimumValue = 1.0
        sizeSlider.setValue(brush, animated: false)
        colorSlider.setValue(hue, animated: false)
        color = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        colorSlider.thumbTintColor = color
        UIGraphicsBeginImageContext(imageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2))
        context?.addLine(to: CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2))
        context?.setLineCap(.round)
        context?.setLineWidth(CGFloat(brush))
        context?.setStrokeColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        context?.setBlendMode(.normal)
        context?.strokePath()
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func setBrushPreview(){
        imageView.image = nil
        UIGraphicsBeginImageContext(imageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2))
        context?.addLine(to: CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2))
        context?.setLineCap(.round)
        context?.setLineWidth(CGFloat(brush))
        context?.setStrokeColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        context?.setBlendMode(.normal)
        context?.strokePath()
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        delegate.updateBrush(size: sizeSlider.value, hue: colorSlider.value, red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue))
    }
    
    @IBAction func sizeSliderChanged(_ sender: Any) {
        brush = sizeSlider.value
        setBrushPreview()
    }
    
    @IBAction func colorSliderChanged(_ sender: Any) {
        colorSlider.thumbTintColor = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        color = colorSlider.thumbTintColor
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Float(r)
        green = Float(g)
        blue = Float(b)
        setBrushPreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        delegate.updateBrush(size: sizeSlider.value, hue: colorSlider.value, red: r, green: g, blue: b)
    }

}
