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
    
    var chatID:String!
    var groupChat:Group!
    
    @IBOutlet weak var navItem: UINavigationItem!
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var ref: CollectionReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        cache.getGroup(id: chatID) { (group) in
            if let group = group {
                Timestamp.getServerTime { (serverTime) in
                    if let lastActive = serverTime {
                        self.navItem.title = group.name
                        let data:[String:Any] = [
                            "name": group.name,
                            "numMembers": group.numMembers,
                            "lastActive": lastActive.dateValue() as NSDate,
                            "unreadMessages": 0 as Int32,
                            "active": true
                        ]
                        cache.updateGroup(id: group.id, data: data, complete: { (groupChat) in
                            self.groupChat = groupChat
                            self.checkListener()
                        })
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        listener?.remove()
        let currentUser = Auth.auth().currentUser!
        let userRef = Firestore.firestore().collection("groups").document(groupChat.id).collection("usersInGroup").document(currentUser.uid)
        Timestamp.getServerTime { (serverTime) in
            if let lastActive = serverTime {
                let data:[String:Any] = [
                    "name": self.groupChat.name,
                    "numMembers": self.groupChat.numMembers,
                    "lastActive": lastActive.dateValue() as NSDate,
                    "unreadMessages": 0 as Int32,
                    "active": false
                ]
                cache.updateGroup(id: self.groupChat.id, data: data, complete: {_ in })
                userRef.updateData(["lastActive": lastActive.firebaseTimestamp()])
            }
        }
    }
    
    private func checkListener() {
        ref = db.collection("groups").document(groupChat.id).collection("messages")
        listener = ref?.addSnapshotListener{ query,error in
            guard let snapshot = query else {
                print("ERROR")
                return
            }
            
            snapshot.documentChanges.forEach{ change in
                self.handleDocumentChange(change)
            }
            self.updateMessages()
        }
    }
    
    
    @IBAction func settingsAction(_ sender: Any) {
        performSegue(withIdentifier: "settingsIdentifier", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "settingsIdentifier") {
            let dest: GroupChatSettingsViewController = segue.destination as! GroupChatSettingsViewController
            dest.identity = "settingsIdentifier"
            dest.groupName = groupChat.name
            dest.groupID = groupChat.id
        }
    }
    
    private func save(_ message: Message) {
        var content = message.content
        if message.image != nil {
            content = message.postID
        }
        ref?.document(message.messageId).setData([
            "sent": message.sentDate,
            "uid": message.sender.id,
            "image": message.image != nil,
            "content": content
        ]) { error in
            if error != nil {
                print("ERROR")
                return
            }
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    func addPost(post: PostData) {
        //add post?
    }
    
    private func updateMessages(){
        let scrollViewHeight = messagesCollectionView.bounds.height
        let scrollSizeHeight = messagesCollectionView.contentSize.height
        let bottomInset = messagesCollectionView.contentInset.bottom
        let scrollBottomOffset = scrollSizeHeight + bottomInset - scrollViewHeight
        let shouldScrolltoBottom = messagesCollectionView.contentOffset.y >= scrollBottomOffset
        
        messagesCollectionView.reloadData()
        
        if shouldScrolltoBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
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
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        if change.document.exists {
            if change.type == .added {
                let data = change.document.data()
                let id = change.document.documentID
                let content = data["content"] as! String
                let isImage = data["image"] as! Bool
                let uid = data["uid"] as! String
                let date = data["sent"] as! Firebase.Timestamp
                cache.getProfile(uid: uid) { (profile) in
                    if let profile = profile {
                        let name = profile.username
                        let sender = Sender(id: uid, displayName: name)
                        if isImage {
                            cache.getPost(id: content) { (post) in
                                Timestamp.getServerTime { (serverTime) in
                                    if let serverTime = serverTime {
                                        let expireTime = Timestamp(s:serverTime.dateValue().timeIntervalSince1970 - 86400)
                                        if let post = post, Timestamp(s: post.seconds, n: post.nanoseconds) > expireTime {
                                            let postImageURL = post.photoURL
                                            cache.getImage(imageURL: postImageURL, complete: { (cachedImage) in
                                                if let cachedImage = cachedImage {
                                                    let image = MessageImage(image: cachedImage, post: content)
                                                    let message = Message(id: id, content: content, image: image, sender: sender, date: date.dateValue())
                                                    self.insertMessage(message)
                                                }
                                            })
                                        }
                                        else{
                                            let image = MessageImage(image: #imageLiteral(resourceName: "expired"), post: content)
                                            let message = Message(id: id, content: content, image: image, sender: sender, date: date.dateValue())
                                            self.insertMessage(message)
                                        }
                                    }
                                }
                            }
                        }
                        else{
                            let message = Message(id: id, content: content, image: nil, sender: sender, date: date.dateValue())
                            self.insertMessage(message)
                        }
                    }
                }
            }
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        Timestamp.getServerTime { (serverTime) in
            if let serverTime = serverTime {
                let message = Message(id: (self.ref?.document().documentID)!, content:text, image:nil, sender: self.currentSender(), date: serverTime.dateValue())
                self.save(message)
                inputBar.inputTextView.text = ""
            }
        }
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
        cache.getProfile(uid: message.sender.id) { (profile) in
            if let profile = profile {
                let profilePicURL = profile.profilePicURL
                cache.getImage(imageURL: profilePicURL, complete: { (avatar) in
                    if let avatar = avatar {
                        avatarView.image = avatar
                    }
                })
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
                    cache.getPost(id: item.postID) { (post) in
                        if let post = post {
                            postVC.post = post.id
                            postVC.index = indexPath
                            postVC.delegate = self
                            self.navigationController?.pushViewController(postVC, animated: true)
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let message = messages[indexPath.section]
            let userID = message.sender.id
            let profileStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
            if let profileVC = profileStoryBoard.instantiateViewController(withIdentifier: "profileView") as? ProfileViewController {
                cache.getProfile(uid: userID) { (profile) in
                    if let profile = profile {
                        profileVC.uid = profile.id
                        self.navigationController?.pushViewController(profileVC, animated: true)
                    }
                }
            }
        }
    }
    
}
