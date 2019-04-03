//
//  MainViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController, UITabBarControllerDelegate {
    
    var currentController:UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
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
