//
//  MainViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

class MainViewController: UITabBarController, UITabBarControllerDelegate {
    
    var currentController:UIViewController?
    var groups:[String:Bool] = [:]
    var unreadMessages:[String:Int32] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        let currentUser = Auth.auth().currentUser!
        let groupsRef = Firestore.firestore().collection("users").document(currentUser.uid).collection("groups")
        groupsRef.addSnapshotListener { (query, err) in
            if let query = query {
                query.documentChanges.forEach { change in
                    if change.type == .added {
                        let groupId = change.document.documentID
                        self.groups[groupId] = true
                        if self.unreadMessages[groupId] == nil {
                            cache.getGroup(id: groupId, complete: { (group) in
                                if let group = group {
                                    print("UNREAD: "+String(group.unreadMessages))
                                    self.unreadMessages[group.id] = group.unreadMessages
                                    self.updateMessageCounter()
                                }
                            })
                            cache.addGroupUpdateListener(id: groupId) { (group) in
                                if let group = group {
                                    if let inGroup = self.groups[group.id], inGroup {
                                        self.unreadMessages[group.id] = group.unreadMessages
                                    }
                                    else{
                                        self.unreadMessages[group.id] = nil
                                    }
                                }
                                self.updateMessageCounter()
                            }
                        }
                    }
                    if change.type == .removed {
                        self.groups[change.document.documentID] = false
                        self.unreadMessages[change.document.documentID] = nil
                    }
                }
            }
        }
    }
    
    func updateMessageCounter(){
        var count = 0 as Int32
        for numMessages in Array(unreadMessages.values) {
            count += numMessages
        }
        if let items = tabBar.items {
            let item = items[2]
            if count > 0 {
                item.badgeValue = "\(count)"
            }
            else{
                item.badgeValue = nil
            }
        }
    }
    
    // UITabBarDelegate
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //print("Selected item")
    }
    
    // UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        var sameController = false
        if let current = currentController {
            sameController = current == viewController
        }
        currentController = viewController
        var vc = viewController
        if vc.isKind(of: UINavigationController.self){
            let navController = vc as! UINavigationController
            vc = navController.topViewController!
        }
        if vc.isKind(of: TabViewController.self){
            let tabController = vc as! TabViewController
            if sameController {
                tabController.update()
            }
        }
    }
}
