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
        checkListerner()
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
    }
    
    private func checkListerner() {
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
    
    func addPost(post: PostData) {
        //add post?
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
                    cache.getPost(id: postID) { (post) in
                        if let post = post {
                            let postImageURL = post.photoURL
                            cache.getImage(imageURL: postImageURL, complete: { (cachedImage) in
                                if let cachedImage = cachedImage {
                                    let image = MessageImage(image: cachedImage, post: postID)
                                    let message = Message(id: id, content: content, image: image, sender: sender, date: date.dateValue())
                                    self.insertMessage(message)
                                }
                            })
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
                        profileVC.userID = profile.id
                        self.navigationController?.pushViewController(profileVC, animated: true)
                    }
                }
            }
        }
    }
    
}
