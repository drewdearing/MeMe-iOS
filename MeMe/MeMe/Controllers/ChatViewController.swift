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

class ChatViewController: MessagesViewController, MessageInputBarDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var chat:GroupChat!
    
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var ref: CollectionReference?
    

    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    private func save(_ message: Message) {
        ref?.document(message.messageId).setData([
            "id": message.messageId,
            "sent": message.sentDate,
            "uid": message.sender.id,
            "name": message.sender.displayName,
            "image": message.image != nil,
            "imageURL": message.imageURL,
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
            let data = change.document.data()
            let id = data["id"] as! String
            let content = data["content"] as! String
            let isImage = data["image"] as! Bool
            let imageURL = data["imageURL"] as! String
            var image:MessageImage?
            let uid = data["uid"] as! String
            let name = data["name"] as! String
            let date = data["sent"] as! Firebase.Timestamp
            let sender = Sender(id: uid, displayName: name)
            if isImage {
                image = MessageImage(url: imageURL)
            }
            let message = Message(id: id, content: content, image: image, sender: sender, date: date.dateValue())
            switch change.type {
            case .added:
                insertMessage(message)
            default:
                break
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
    
}
