//
//  GalleryCollectionViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "GalleryCellIdentifier"

private let editMemeStoryIdentifier = "EditMemeVCID"

class GalleryViewController: UIViewController, UICollectionViewDataSource,
    UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    private var images: [UIImage] = []
    var delegate:NewMemeDelegate?
    private var selectedCellIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        galleryCollectionView.delegate = self
        galleryCollectionView.dataSource = self
        
        // Do any additional setup after loading the view.
        fetchGalleryImages()
    }
    
    private func fetchGalleryImages() {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions =  PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false, selector: nil)]
        
        if let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions) {
            if fetchResult.count > 0 {
                for index in 0 ..< fetchResult.count {
                    imageManager.requestImage(for: fetchResult.object(at: index), targetSize: CGSize(width: 200, height: 200), contentMode: PHImageContentMode.aspectFill, options: requestOptions) { (image, [AnyHashable : Any]?) in
                        self.images.append(image!)
                    }
                }
            } else {
                self.galleryCollectionView?.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        // Configure the cell
        if let imageView = cell.viewWithTag(25) as? UIImageView {
            imageView.image = images[indexPath.row]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 3 - 1
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mainStoryBoard: UIStoryboard = UIStoryboard(name: "NewMeme", bundle: nil)
        if let editMemeVCDestination = mainStoryBoard.instantiateViewController(withIdentifier: editMemeStoryIdentifier) as? EditMemeViewController {
            editMemeVCDestination.selectedImage = images[indexPath.row]
            editMemeVCDestination.delegate = delegate
            self.navigationController?.pushViewController(editMemeVCDestination, animated: true)
        }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
