//
//  TabView.swift
//  MeMe
//
//  Created by Drew Dearing on 4/2/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class TabView: UIView {

    func push(view:NavigationView){
        addSubview(view)
        view.frame = self.bounds
    }
    
    func pop(){
        if subviews.count > 1 {
            let view = subviews[subviews.count - 1]
            view.removeFromSuperview()
        }
    }

}
