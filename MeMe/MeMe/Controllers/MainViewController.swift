//
//  MainViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

private let groupChatSettingsStoryIdentifier = "GroupChatSettingsVCID"
private let profileSettingsStoryIdentifier = "ProfileSettingsVCID"

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
    
    @IBAction func pressLeftNavButton(_ sender: Any) {
        performSegue(withIdentifier: "newMemeSegue", sender: self)
    }
    
    @IBAction func pressRightNavButton(_ sender: Any) {
        if let i = currentView {
            switch i {
            case 2:
                performSegue(withIdentifier: "GroupChatSettingsSegue", sender: self)
                break
            case 3:
                performSegue(withIdentifier: "ProfileSettingsSegue", sender: self)
                break
            default:
                break
            }
        }
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
            if v.isKind(of: FeedView.self) {
                delegates.append(v as! editMemeVCDelegate)
            }
            views[i] = v
            navBarItem.title = navBarTitles[i]
        }
        updateNav(i)
        self.currentView = i
    }
    
    func updateNav(_ i:Int){
        switch i {
        case 0, 1:
            navBarItem.rightBarButtonItem!.isEnabled = false
            navBarItem.rightBarButtonItem!.tintColor = UIColor.clear
            navBarItem.leftBarButtonItem!.isEnabled = true
            navBarItem.leftBarButtonItem!.tintColor = nil
            break
        case 2:
            navBarItem.rightBarButtonItem!.image = #imageLiteral(resourceName: "plus-filled")
            navBarItem.rightBarButtonItem!.isEnabled = true
            navBarItem.rightBarButtonItem!.tintColor = nil
            navBarItem.leftBarButtonItem!.isEnabled = false
            navBarItem.leftBarButtonItem!.tintColor = UIColor.clear
            break
        case 3:
            navBarItem.rightBarButtonItem!.image = #imageLiteral(resourceName: "settings")
            navBarItem.rightBarButtonItem!.isEnabled = true
            navBarItem.rightBarButtonItem!.tintColor = nil
            navBarItem.leftBarButtonItem!.isEnabled = false
            navBarItem.leftBarButtonItem!.tintColor = UIColor.clear
            break
        default:
            break
        }
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
