//
//  MainViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITabBarDelegate {

    @IBOutlet weak var currentScreenView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var navBarItem: UINavigationItem!
    
    let views = [HomeView(), DiscoverView(), MessageView(), ProfileView()]
    let navBarTitles = ["Your Feed", "Discover", "Direct Messages", "Profile"]
    
    var currentView:Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tabBar.delegate = self
    }
    
    private func setScreenView(i: Int){
        if let current = self.currentView {
            views[current].removeFromSuperview()
        }
        currentScreenView.addSubview(views[i])
        views[i].frame = currentScreenView.bounds
        navBarItem.title = navBarTitles[i]
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
