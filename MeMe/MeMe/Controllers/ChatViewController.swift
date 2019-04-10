//
//  ChatViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 4/6/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import MessageKit
import MessageInputBar
import Firebase
import Photos

class ChatViewController: MessagesViewController, MessageInputBarDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate, IndividualPostDelegate {
    
    var chat:GroupChat!
    
    @IBOutlet weak var navItem: UINavigationItem!
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var ref: CollectionReference?
    


    override func viewDidLoad() {
        super.viewDidLoad()
        navItem.title = chat.groupChatName
        print("id is: " + (chat?.groupId)!)
        ref = db.collection("groups").document((chat?.groupId)!).collection("messages")
        listener = ref?.addSnapshotListener{ query,error in
            guard let snapshot = query else {
                print("ERROR")
                return
            }
            
            snapshot.documentChanges.forEach{ change in
                self.handleDocumentChange(change)
            }
        }
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
    }
    
    
    @IBAction func settingsAction(_ sender: Any) {
        performSegue(withIdentifier: "settingsIdentifier", sender: self)
        

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "settingsIdentifier") {
            let dest: GroupChatSettingsViewController = segue.destination as! GroupChatSettingsViewController
            dest.identity = "settingsIdentifier"
            dest.groupName = chat.groupChatName
            dest.groupID = chat.groupId
        }
    }
    private func save(_ message: Message) {
        ref?.document(message.messageId).setData([
            "id": message.messageId,
            "sent": message.sentDate,
            "uid": message.sender.id,
            "name": message.sender.displayName,
            "meme": message.image != nil,
            "post": message.postID,
            "content": message.content
        ]) { error in
            if let e = error {
                print("ERROR")
                return
            }
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    private func insertMessage(_ message: Message) {
        guard !messages.contains(where: { (m) -> Bool in
            return m.messageId == message.messageId
        }) else {
            return
        }
        messages.append(message)
        messages.sort { (a, b) -> Bool in
            a.sentDate.timeIntervalSince1970 < b.sentDate.timeIntervalSince1970
        }
        
        let scrollViewHeight = messagesCollectionView.bounds.height
        let scrollSizeHeight = messagesCollectionView.contentSize.height
        let bottomInset = messagesCollectionView.contentInset.bottom
        let scrollBottomOffset = scrollSizeHeight + bottomInset - scrollViewHeight
        
        let isLatestMessage = messages[0].messageId == message.messageId
        let shouldScrolltoBottom = messagesCollectionView.contentOffset.y >= scrollBottomOffset && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrolltoBottom{
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        if change.document.exists {
            if change.type == .added {
                let data = change.document.data()
                let id = data["id"] as! String
                let content = data["content"] as! String
                let isImage = data["meme"] as! Bool
                let postID = data["post"] as! String
                let uid = data["uid"] as! String
                let name = data["name"] as! String
                let date = data["sent"] as! Firebase.Timestamp
                let sender = Sender(id: uid, displayName: name)
                if isImage {
                    if let cachedImage = cache.getImage(id: postID){
                        let image = MessageImage(image: cachedImage, post: postID)
                        let message = Message(id: id, content: content, image: image, sender: sender, date: date.dateValue())
                        insertMessage(message)
                    }
                    else{
                        db.collection("post").document(postID).getDocument { (postDoc, err) in
                            if let doc = postDoc {
                                if doc.exists {
                                    if let data = doc.data() {
                                        let url = data["photoURL"] as! String
                                        let image = MessageImage(url: url, post: postID)
                                        let message = Message(id: id, content: content, image: image, sender: sender, date: date.dateValue())
                                        self.insertMessage(message)
                                    }
                                }
                            }
                        }
                    }
                }
                else{
                    let message = Message(id: id, content: content, image: nil, sender: sender, date: date.dateValue())
                    insertMessage(message)
                }
            }
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let message = Message(id: (ref?.document().documentID)!, content:text, image:nil, sender: currentSender())
        save(message)
        inputBar.inputTextView.text = ""
    }
    
    func currentSender() -> Sender {
        let profile = getCurrentProfile()
        return Sender(id: Auth.auth().currentUser!.uid, displayName: profile!.username)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        /* check if avatar is in local cache*/
        if let avatar = cache.getProfilePic(uid: message.sender.id) {
            avatarView.image = avatar
        } else {
            db.collection("users").document(message.sender.id).getDocument { (userDoc, err) in
                if let doc = userDoc{
                    if doc.exists {
                        let profileURL = doc.data()!["profilePicURL"] as! String
                        let url = URL(string: profileURL)
                        let data = try? Data(contentsOf: url!)
                        if let imgData = data {
                            let image = UIImage(data:imgData)
                            DispatchQueue.main.async {
                                avatarView.image = image
                            }
                            cache.addProfilePic(id: message.sender.id, image: image)
                        }
                    }
                }
            }
        }
    }
    
    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) -> Bool {
        return false
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath,
                        in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath,
                           with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func addPost(post: FeedCellData, feed: Bool, update: Bool) {
        _ = cache.addPost(data: post, feed: feed)
    }
    
    func refreshCell(index: IndexPath) {
        //dont need
    }
    
    func messageTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath) -> NSAttributedString? {
        
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ]
        )
    }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 12
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let message = messages[indexPath.section]
            switch message.kind {
            case .photo(let item):
                let item = item as! MessageImage
                print(item.postID)
                let postStoryBoard: UIStoryboard = UIStoryboard(name: "Post", bundle: nil)
                if let postVC = postStoryBoard.instantiateViewController(withIdentifier: "individualPost") as? PostViewController {
                    if let feedCell = cache.getPost(id: item.postID){
                        postVC.post = feedCell
                        postVC.index = indexPath
                        postVC.delegate = self
                        navigationController?.pushViewController(postVC, animated: true)
                    }
                    else{
                        print("not cached")
                        Firestore.firestore().collection("post").document(item.postID).getDocument { (postDoc, err) in
                            if let doc = postDoc {
                                if doc.exists {
                                    if let data = doc.data() {
                                        let description = data["description"] as! String
                                        let uid = data["uid"] as! String
                                        let post = doc.documentID
                                        let imageURL = data["photoURL"] as! String
                                        let upvotes = data["upvotes"] as! Int
                                        let downvotes = data["downvotes"] as! Int
                                        let fbTimestamp = data["timestamp"] as! Firebase.Timestamp
                                        let timestamp = Timestamp(s:Int(fbTimestamp.dateValue().timeIntervalSince1970))
                                        var cellData = FeedCellData(username: "", description: description, uid: uid, post: post, imageURL: imageURL, profilePicURL: "", upvotes: upvotes, downvotes: downvotes, timestamp: timestamp, upvoted: false, downvoted: false)
                                        Firestore.firestore().collection("users").document(uid).getDocument(completion: { (userDoc, err) in
                                            if let user = userDoc {
                                                if user.exists {
                                                    if let userData = user.data() {
                                                        let username = userData["username"] as! String
                                                        let profileURL = userData["profilePicURL"] as! String
                                                        cellData.username = username
                                                        cellData.profilePicURL = profileURL
                                                        Firestore.firestore().collection("post").document(item.postID).collection("votes").document(uid).getDocument(completion: { (voteDoc, err) in
                                                            if let vote = voteDoc {
                                                                if vote.exists {
                                                                    if let voteData = vote.data() {
                                                                        let up = voteData["up"] as! Bool
                                                                        cellData.downvoted = !up
                                                                        cellData.upvoted = up
                                                                    }
                                                                }
                                                                let feedCell = cache.addPost(data: cellData, feed: false)
                                                                postVC.post = feedCell
                                                                postVC.index = indexPath
                                                                postVC.delegate = self
                                                                self.navigationController?.pushViewController(postVC, animated: true)
                                                            }
                                                        })
                                                    }
                                                }
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
}
