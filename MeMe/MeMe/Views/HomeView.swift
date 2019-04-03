//
//  HomeView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import CoreData

let HomeTableCellId = "FeedTableViewCell"
class HomeView: FeedView {

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
        Bundle.main.loadNibNamed("HomeView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        tableView.register(UINib.init(nibName: HomeTableCellId, bundle: nil), forCellReuseIdentifier: HomeTableCellId)
        tableView.delegate = self
        tableView.dataSource = self
        self.urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/getUserFeed"
        loadPosts()
    }
    
    override func loadPosts(predicate: NSPredicate? = NSPredicate(format: "feed == TRUE")) {
        super.loadPosts(predicate:predicate)
    }
    
    override func cellFromData(post: FeedCellData, context: NSManagedObjectContext) -> FeedCell? {
        var cell = super.cellFromData(post: post, context: context)
        if cell != nil {
            cell!.feed = true
        }
        return cell
    }
    
    override func update() {
        DispatchQueue.main.async {
            self.postData = self.postData.sorted(by: {$0.seconds > $1.seconds})
            self.tableView.reloadData()
        }
    }
    
}
