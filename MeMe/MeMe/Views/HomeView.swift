//
//  HomeView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

struct FeedContainer:Codable {
    var posts: [FeedCellData]
}

struct FeedCellData: Codable {
    var username: String
    var description: String
    var uid: String
    var post: String
    var imageURL: String
    var profilePicURL: String
    var upvotes: Int
    var downvotes: Int
}

let HomeTableCellId = "FeedTableViewCell"
class HomeView: UIView, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var postData:[FeedCellData] = []
    var currentPage = 1
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableCellId, for: indexPath as IndexPath) as! FeedTableViewCell
        cell.cellTitle.text = postData[indexPath.row].username
        cell.downVoteCounter.text = String(postData[indexPath.row].downvotes)
        cell.descriptionLabel.text = postData[indexPath.row].description
        cell.upVoteCounter.text = String(postData[indexPath.row].upvotes)
        cell.memeURL = postData[indexPath.row].imageURL
        cell.uid = postData[indexPath.row].uid
        cell.postID = postData[indexPath.row].post
        cell.profileURL = postData[indexPath.row].profilePicURL
        
        if cell.memeURL != nil {
            let url = URL(string: cell.memeURL!)
            let data = try? Data(contentsOf: url!)
            if let imageData = data {
                cell.memePic.image = UIImage(data:imageData)
            }
        }
        
        if cell.profileURL != nil {
            let url = URL(string: cell.profileURL!)
            let data = try? Data(contentsOf: url!)
            if let imageData = data {
                cell.profilePic.image = UIImage(data:imageData)
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 352
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //deselect row when tapped
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
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
        getPosts()
    }
    
    private func getPosts() {
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = "https://us-central1-meme-d3805.cloudfunctions.net/getUserFeed"
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&page="+String(self.currentPage))
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
                guard let data = data else { return }
                do {
                    let ideaDeck = try JSONDecoder().decode(FeedContainer.self, from: data)
                    self.postData = ideaDeck.posts
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
}
