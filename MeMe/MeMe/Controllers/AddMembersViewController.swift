//
//  AddMembersViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class AddMembersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var potentialMembersTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    private var potentialMembers: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        potentialMembersTableView.delegate = self
        potentialMembersTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return potentialMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "potentialMembersCellIdentifier", for: indexPath as IndexPath) as? CurrentUserTableViewCell
        
        let row = indexPath.row
        let user = potentialMembers[row]
        
        return cell!
    }

    @IBAction func addButton(_ sender: Any) {
    }
}
