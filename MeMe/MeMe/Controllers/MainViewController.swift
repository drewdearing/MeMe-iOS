//
//  MainViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITabBarDelegate, editMemeVCDelegate {

    @IBOutlet weak var currentScreenView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var navBarItem: UINavigationItem!
    
    let views = [HomeView(), DiscoverView(), MessageView(), ProfileView()]
    let navBarTitles = ["Your Feed", "Discover", "Direct Messages", "Profile"]
    var delegates:[editMemeVCDelegate] = []
    
    var currentView:Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        delegates.append(views[0] as! editMemeVCDelegate)
        delegates.append(views[1] as! editMemeVCDelegate)
    }
    
    private func setScreenView(i: Int){
        if let current = self.currentView {
            views[current].removeFromSuperview()
        }
        currentScreenView.addSubview(views[i])
        views[i].frame = currentScreenView.bounds
        //navBarItem.title = navBarTitles[i]
        self.currentView = i
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let current = self.currentView {
            setScreenView(i: current)
        }
        else{
            setScreenView(i: 0)
        }
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        setScreenView(i: item.tag)
    }
    
    func addMeme(newFeed: FeedCellData) {
        for delegate in delegates {
            delegate.addMeme(newFeed: newFeed)
        }
    }

}
