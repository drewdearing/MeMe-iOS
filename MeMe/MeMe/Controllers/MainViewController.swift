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
    
    var views:[TabView?] = [HomeView(), nil, nil, nil]
    let navBarTitles = ["Your Feed", "Discover", "Direct Messages", "Profile"]
    let viewTypes = [HomeView.self, DiscoverView.self, MessageView.self, ProfileView.self]
    var delegates:[editMemeVCDelegate] = []
    
    var currentView:Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        delegates.append(views[0] as! editMemeVCDelegate)
        navBarItem.backBarButtonItem = UIBarButtonItem(title: "Hi", style: .plain, target: nil, action: nil)
        navBarItem.backBarButtonItem?.setTitlePositionAdjustment(UIOffset(horizontal: -10, vertical: -10), for: .default)
    }
    
    @IBAction func pressLeftNavButton(_ sender: Any) {
        if let i = currentView {
            if let v = views[i] {
                if v.subviews.count > 1 {
                    v.pop()
                    updateNav(i)
                }
                else{
                    switch i {
                    case 0,1:
                        performSegue(withIdentifier: "newMemeSegue", sender: self)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func pressRightNavButton(_ sender: Any) {
        if let i = currentView {
            if let v = views[i] {
                if v.subviews.count > 1 {
                    let subView = v.subviews[v.subviews.count - 1] as! NavigationView
                    subView.pressRightNavButton()
                }
                else{
                    switch i {
                    case 2:
                        if let v = views[i] {
                            let new = GroupSettingsView()
                            v.push(view: new)
                            updateNav(i)
                        }
                        break
                    case 3:
                        performSegue(withIdentifier: "ProfileSettingsSegue", sender: self)
                        break
                    default:
                        break
                    }
                }
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
        }
        else{
            let v = viewTypes[i].init()
            currentScreenView.addSubview(v)
            v.frame = currentScreenView.bounds
            if v.isKind(of: FeedView.self) {
                delegates.append(v as! editMemeVCDelegate)
            }
            views[i] = v
        }
        updateNav(i)
        self.currentView = i
    }
    
    func updateNav(_ i:Int){
        if let v = views[i] {
            if(v.subviews.count > 1){
                let navigationView = v.subviews[v.subviews.count - 1] as! NavigationView
                navBarItem.title = navigationView.title
                navBarItem.leftBarButtonItem!.image = #imageLiteral(resourceName: "back-1")
                navBarItem.leftBarButtonItem!.isEnabled = true
                navBarItem.leftBarButtonItem!.tintColor = nil
                
                if navigationView.rightNavButton {
                    navBarItem.rightBarButtonItem?.isEnabled = true
                    navBarItem.rightBarButtonItem?.tintColor = nil
                    navBarItem.rightBarButtonItem?.image = navigationView.rightNavButtonIcon
                }
                else{
                    navBarItem.rightBarButtonItem?.isEnabled = false
                    navBarItem.rightBarButtonItem?.tintColor = UIColor.clear
                }
            }
            else{
                switch i {
                case 0, 1:
                    navBarItem.leftBarButtonItem!.image = #imageLiteral(resourceName: "compose")
                    navBarItem.rightBarButtonItem!.isEnabled = false
                    navBarItem.rightBarButtonItem!.tintColor = UIColor.clear
                    navBarItem.leftBarButtonItem!.isEnabled = true
                    navBarItem.leftBarButtonItem!.tintColor = nil
                    navBarItem.title = navBarTitles[i]
                    break
                case 2:
                    navBarItem.rightBarButtonItem!.image = #imageLiteral(resourceName: "plus-filled")
                    navBarItem.rightBarButtonItem!.isEnabled = true
                    navBarItem.rightBarButtonItem!.tintColor = nil
                    navBarItem.leftBarButtonItem!.isEnabled = false
                    navBarItem.leftBarButtonItem!.tintColor = UIColor.clear
                    navBarItem.title = navBarTitles[i]
                    break
                case 3:
                    navBarItem.rightBarButtonItem!.image = #imageLiteral(resourceName: "settings")
                    navBarItem.rightBarButtonItem!.isEnabled = true
                    navBarItem.rightBarButtonItem!.tintColor = nil
                    navBarItem.leftBarButtonItem!.isEnabled = false
                    navBarItem.leftBarButtonItem!.tintColor = UIColor.clear
                    navBarItem.title = navBarTitles[i]
                    break
                default:
                    break
                }
            }
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
