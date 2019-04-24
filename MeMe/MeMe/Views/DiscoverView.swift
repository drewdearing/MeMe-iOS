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
    let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/getDiscoverFeed"
    
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
        reloadPosts()
    }
    
    override func update(){
        DispatchQueue.main.async {
            let newData = Array(self.postData.values).sorted(by: {($0.upvotes - $0.downvotes) > ($1.upvotes - $1.downvotes)})
            self.data = newData
            self.tableView.reloadData()
        }
    }
    
    override func addPost(post: PostData) {
        let score = post.upvotes - post.downvotes
        let newData = Array(self.postData.values).sorted(by: {($0.upvotes - $0.downvotes) > ($1.upvotes - $1.downvotes)})
        if newData.count > 0 {
            let topPost = newData[0]
            if score > (topPost.upvotes - topPost.downvotes) {
                self.postData[post.id] = post
                self.update()
            }
        }
    }
    
    override func getPosts(complete: @escaping (FeedContainer) -> Void) {
        let urlPathBase = urlPath
        let request = NSMutableURLRequest()
        request.url = URL(string: urlPathBase)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            guard let data = data else { return }
            do {
                let postContainer = try JSONDecoder().decode(FeedContainer.self, from: data)
                complete(postContainer)
            } catch let jsonErr {
                print("Error: \(jsonErr)")
            }
        }
        task.resume()
    }
    
    override func refreshCell(index: IndexPath) {
        tableView.reloadRows(at: [index], with: .automatic)
    }
    
    func scrollToTop() {
        if data.count > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}
