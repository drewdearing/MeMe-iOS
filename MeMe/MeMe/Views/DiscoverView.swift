//
//  DiscoverView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class DiscoverView: UIView {

    @IBOutlet var contentView: UIView!

    override init(frame: CGRect){
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("DiscoverView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
    }

}
