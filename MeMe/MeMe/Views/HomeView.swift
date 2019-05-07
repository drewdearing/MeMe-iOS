//
//  HomeView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import CoreData
import Firebase

let HomeTableCellId = "FeedTableViewCell"
class HomeView: FeedView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/getUserFeed"
    
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
        table = tableView
        reloadPosts()
    }
    
    override func getPosts(complete: @escaping (FeedContainer) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
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
    }
    
    override func getMorePosts(complete: @escaping (FeedContainer) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            if data.count > 0 {
                let post = data[data.count-1]
                var timestamp = Double(post.timestamp._seconds)
                timestamp += Double(post.timestamp._nanoseconds) * 0.000000001
                urlPathBase = urlPathBase.appending("&timestamp="+String(timestamp))
            }
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
    }
    
    override func addPost(post: PostData) {
        let currentUID = Auth.auth().currentUser?.uid
        cache.getProfile(uid: post.uid) { (profile) in
            if let profile = profile, profile.following || post.uid == currentUID {
                self.postData[post.id] = post
                self.update()
            }
        }
    }
    
    override func sortData() -> [PostData] {
        return Array(self.postData.values).sorted(by: {$0.timestamp > $1.timestamp})
    }
}
