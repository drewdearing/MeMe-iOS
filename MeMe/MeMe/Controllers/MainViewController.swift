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
    
    var views:[UIView?] = [HomeView(), nil, nil, nil]
    let navBarTitles = ["Your Feed", "Discover", "Direct Messages", "Profile"]
    let viewTypes = [HomeView.self, DiscoverView.self, MessageView.self, ProfileView.self]
    var delegates:[editMemeVCDelegate] = []
    
    var currentView:Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        delegates.append(views[0] as! editMemeVCDelegate)
    }
    
    private func setScreenView(i: Int){
        if let current = self.currentView {
            if let v = views[current] {
                v.removeFromSuperview()
            }
        }
        if let v = views[i] {
            currentScreenView.addSubview(v)
            v.frame = currentScreenView.bounds
            navBarItem.title = navBarTitles[i]
        }
        else{
            let v = viewTypes[i].init()
            currentScreenView.addSubview(v)
            v.frame = currentScreenView.bounds
            if i <= 1 {
                delegates.append(v as! editMemeVCDelegate)
            }
            views[i] = v
            navBarItem.title = navBarTitles[i]
        }
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
    
    func addMeme(post: FeedCellData) {
        print(delegates.count)
        for delegate in delegates {
            delegate.addMeme(post: post)
        }
    }

}
