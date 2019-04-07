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
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        
        // 1
        guard let profile = getCurrentProfile() else {return}
        let message = Message(id: (ref?.document().documentID)!, kind: MessageKind.text(text), sender: currentSender())
        
        // 2
        save(message)
        
        // 3
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
        
        MessageKind.text("hj").text
        
        
        
        ref?.document(message.messageId).setData([
            "id": message.messageId,
            "sent": message.sentDate,
            "uid": message.uid,
            "name": "yikes",
            "kind": [
                "type": message.kind
            ]
            
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
            var kind:MessageKind?
            if let kindData = data["kind"] as? [String:String] {
                if kindData["type"] == "text" {
                    kind = MessageKind.text(kindData["content"]!)
                }
            }
            let message = Message(id: data["id"] as! String, kind: kind!, sender: Sender(id: data["uid"] as! String, displayName: data["name"] as! String))
            switch change.type {
            case .added:
                insertMessage(message)
                
            default:
                break
            }
        }
    }
    
}
