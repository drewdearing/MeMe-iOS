//
//  DiscoverView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class DiscoverView: FeedView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
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
        tableView.register(UINib.init(nibName: HomeTableCellId, bundle: nil), forCellReuseIdentifier: HomeTableCellId)
        tableView.delegate = self
        tableView.dataSource = self
        self.urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/getDiscoverFeed"
        loadPosts()
    }
    
    override func update(){
        DispatchQueue.main.async {
            self.postData = self.postData.sorted(by: {($0.upvotes - $0.downvotes) > ($1.upvotes - $1.downvotes)})
            self.tableView.reloadData()
        }
    }
    
}
