import UIKit
import InputBarAccessoryView
import Firebase
import MessageKit
import FirebaseFirestore
import SDWebImage

class ChatViewController: MessagesViewController {

   // var currentUser = (Firestore.firestore().auth() as AnyObject).currentUser
    let fireStore = FirebaseManager.instance
    var user: String?
    var userID: String?
    var x: Double?
    var y: Double?
    //var docReference: DocumentReference?
  
    var messages: [Message] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backToLoginButton = UIBarButtonItem(title: "Leave chat", style: .done, target: self, action: #selector(exit))
        let listUsersButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(goInListUsers))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        navigationItem.leftBarButtonItem = backToLoginButton
        navigationItem.setRightBarButtonItems([listUsersButton, refreshButton], animated: true)

        navigationItem.largeTitleDisplayMode = .automatic
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .black
        messageInputBar.sendButton.setTitleColor(.black, for: .normal)
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        loadChat()
 }
    
    @objc private func exit() {
        fireStore.leaveChat(userID: userID!, x: x!, y: y!)
        performSegue(withIdentifier: UIConstants.sequeIndificator.map, sender: self)
    }
    
    @objc private func goInListUsers() {
        performSegue(withIdentifier: UIConstants.sequeIndificator.listUsers, sender: self)
    }
    
    @objc private func refresh() {
        loadChat()
    }
    
    private func loadChat() {
        
        fireStore.loadMessage(x: x!,y: y!, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messages):
                self.messages = messages
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom(animated: true)
                }
            case .failure(let error):
                print("\(error)")
            }
        })
    }
}
extension ChatViewController: InputBarAccessoryViewDelegate {
       
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: userID!, senderName: user!)
        
        fireStore.saveMessage(message: message, x: x!, y: y!, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success( _):
                self.loadChat()
            case .failure(let error):
                print("\(error)")
            }
        })
        messages.append(message)
        
        //clearing input field
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard messages[indexPath.section].senderID == userID else { return }
        let indexSet = IndexSet(arrayLiteral: indexPath.section)
        fireStore.deleteMessage(message: messages[indexPath.section], x: x!, y: y!)
        messages.remove(at: indexPath.section)
        messagesCollectionView.deleteSections(indexSet)
    }
}

extension ChatViewController: MessagesDataSource {
    
    func currentSender() -> SenderType {
        return Sender(senderId: userID!, displayName: user!)
       }
       
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
       }
       
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
       }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 12
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName, attributes: [.font: UIFont.systemFont(ofSize: 12)])
    }
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        avatarView.image = UIImage(systemName: UIConstants.Image.person)
    }
    
}

extension ChatViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == UIConstants.sequeIndificator.listUsers,
            let vc = segue.destination as? ListUsersTableVC else { return }
        vc.x = x
        vc.y = y
        vc.user = user
    }
    
}
