//
//  EditToolsViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/10/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

protocol EditToolsDelegate {
    func updateTools(size:Float, hue:Float, red:CGFloat, green:CGFloat, blue:CGFloat, desc:String, text:String, textSize:Float, textHue:Float, draw:Bool)
    func addMeme(post:PostData)
}

class EditToolsViewController: UIViewController {
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var brushSlider: UISlider!
    @IBOutlet weak var colorSlider: UISlider!
    @IBOutlet weak var textSizeSlider: UISlider!
    @IBOutlet weak var textColorSlider: UISlider!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var delegate:EditToolsDelegate!
    var desc:String!
    var red:Float!
    var blue:Float!
    var green:Float!
    var brush:Float!
    var hue:Float!
    var color:UIColor!
    var selectedImage:UIImage!
    var textColor:UIColor!
    var textSize:Float!
    var text:String!
    var textHue:Float!
    var draw:Bool!
    var originalSize:CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionField.text = desc
        brushSlider.maximumValue = 50.0
        brushSlider.minimumValue = 1.0
        brushSlider.setValue(brush, animated: false)
        colorSlider.setValue(hue, animated: false)
        color = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        colorSlider.thumbTintColor = color
        textField.text = text
        textSizeSlider.maximumValue = 70.0
        textSizeSlider.minimumValue = 10.0
        textSizeSlider.setValue(textSize, animated: false)
        textColorSlider.setValue(textHue, animated: false)
        textColor = UIColor(hue: CGFloat(textColorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        textColorSlider.thumbTintColor = textColor
        segmentControl.selectedSegmentIndex = draw ? 0:1
        updateEnabledFields()
    }
    
    func updateEnabledFields() {
        if draw {
            brushSlider.isEnabled = true
            colorSlider.isEnabled = true
            textColorSlider.isEnabled = false
            textSizeSlider.isEnabled = false
            textField.isEnabled = false
        }
        else{
            brushSlider.isEnabled = false
            colorSlider.isEnabled = false
            textColorSlider.isEnabled = true
            textSizeSlider.isEnabled = true
            textField.isEnabled = true
        }
    }
    
    @IBAction func segmentChange(_ sender: Any) {
        draw = segmentControl.selectedSegmentIndex == 0
        updateEnabledFields()
    }
    
    @IBAction func colorSliderChanged(_ sender: Any) {
        colorSlider.thumbTintColor = UIColor(hue: CGFloat(colorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        color = colorSlider.thumbTintColor
    }
    
    @IBAction func textColorSliderChanged(_ sender: Any) {
        textColorSlider.thumbTintColor = UIColor(hue: CGFloat(textColorSlider!.value), saturation: 1, brightness: 1, alpha: 1)
        textColor = colorSlider.thumbTintColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        delegate.updateTools(size: brushSlider.value, hue: colorSlider.value, red: r, green: g, blue: b, desc: descriptionField.text!, text: textField.text!, textSize: textSizeSlider.value, textHue: textColorSlider.value, draw:draw)
    }
    
    func lockUI(){
        descriptionField.isEnabled = false
        doneButton.isEnabled = false
    }
    
    func unlockUI(){
        descriptionField.isEnabled = true
        doneButton.isEnabled = true
    }
    
    @IBAction func done(_ sender: Any) {
        addToStorage()
    }
    
    func cropImage() -> UIImage
    {
        UIGraphicsBeginImageContext(originalSize)
        let width = originalSize.width
        let height = selectedImage.size.height * width / selectedImage.size.width
        let y = (height - originalSize.height) / 2
        selectedImage.draw(in: CGRect(x: 0, y: -y, width: width, height: height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func addToStorage(){
        lockUI()
        SVProgressHUD.show(withStatus: "Posting...")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let image = cropImage()
        let data = image.pngData()
        let color = image.averageColor!.toHexString()
        let ref = Firestore.firestore().collection("post").document()
        let imageName = ref.documentID
        print(imageName)
        let imageRef = storageRef.child("\(imageName).png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        imageRef.putData(data!, metadata: metadata) { (metadata, error) in
            imageRef.downloadURL { (url, error) in
                guard url != nil else {
                    // Uh-oh, an error occurred!
                    self.unlockUI()
                    return
                }
                //do things that u want to do after download is done
                if let urlText = url?.absoluteString {
                    self.addToFirestore(download: urlText, color: color, ref: ref)
                    self.passPost(imageName: imageName, download: urlText, color: color)
                }
            }
        }
    }
    
    func passPost(imageName:String, download:String, color:String){
        let currentUser = Auth.auth().currentUser
        Timestamp.getServerTime { (serverTime) in
            if let serverTime = serverTime {
                let data = PostData(id: imageName, uid: currentUser!.uid, color: color, timestamp: serverTime, upvotes: 0, downvotes: 0)
                SVProgressHUD.dismiss()
                self.delegate?.addMeme(post: data)
                self.dismiss(animated: true)
            }
        }
    }
    
    func addToFirestore(download:String, color:String, ref:DocumentReference){
        let currentUser = Auth.auth().currentUser
        let userPostRef = Firestore.firestore().collection("users").document(currentUser!.uid).collection("posts").document(ref.documentID)
        
        ref.setData([
            "description": self.descriptionField.text!,
            "downvotes": 0,
            "photoURL": download,
            "timestamp": NSDate(),
            "uid": currentUser!.uid,
            "upvotes": 0,
            "score": 0,
            "color": color
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref.documentID)")
            }
        }
        
        userPostRef.setData([
            "timestamp": NSDate(),
            "uid": currentUser!.uid,
            "color": color
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref.documentID)")
            }
        }
    }
}
