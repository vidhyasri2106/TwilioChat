//
//  ChatViewController.swift
//  Twilio Starter App
//
//  Created by Jeffrey Linwood, Kevin Whinnery on 11/29/16.
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//

import UIKit

import TwilioChatClient
import GameplayKit

class ChatViewController: UIViewController, UINavigationControllerDelegate {
    
    // Important - update this URL with your Twilio Function URL
//    let tokenURL = "https://cf175150.ngrok.io/token"
    let tokenURL = "https://digitalexperienceapps-vidhya-ar-twilio.azurewebsites.net/token"

    // Important - this identity would be assigned by your app, for
    // instance after a user logs in
    var identity = "Vidhya"
//    var identity = "Raihana"

    var imagePicker = UIImagePickerController()

    // MARK: Chat variables
    var client: TwilioChatClient? = nil
    var generalChannel: TCHChannel? = nil
    var messages: [TCHMessage] = []
    var pickedImage: UIImage!
    var pickedDocUrl : URL!
    
    @IBOutlet weak var previewImageView: UIView!
    @IBOutlet weak var previewImage: UIImageView!

    // MARK: UI controls
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Listen for keyboard events and animate text field as necessary
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name:Notification.Name.UIKeyboardWillShow,
                                               object: nil);
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name:Notification.Name.UIKeyboardDidShow,
                                               object: nil);
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name:Notification.Name.UIKeyboardWillHide,
                                               object: nil);
        
        // Set up UI controls
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 66.0
        self.tableView.separatorStyle = .none
        
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .overCurrentContext
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        // Create the general channel (for public use) if it hasn't been created yet
        
        let options = [
            TCHChannelOptionFriendlyName: "General Channel",
            TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        if let client = client, let channelsList = client.channelsList() {
            print("channelsList \(channelsList)")

            channelsList.createChannel(options: options, completion: { channelResult, channel in
                if (channelResult.isSuccessful()) {
                    print("Channel created.")
                } else {
                    print("Channel NOT created.")
                }
            })
        }
        
        
        super.viewDidAppear(animated)
        login()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logout()
    }
    
    
    // MARK: Login / Logout
    
    func login() {
        // Fetch Access Token from the server and initialize Chat Client - this assumes you are running
        // the PHP starter app on your local machine, as instructed in the quick start guide
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        let urlString = "\(tokenURL)?identity=\(identity)&device=\(deviceId)"
        
        TokenUtils.retrieveToken(url: urlString) { (token, identity, error) in
            if let token = token {
                // Set up Twilio Chat client
                TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) {
                    (result, chatClient) in
                        self.client = chatClient;
                        // Update UI on main thread
                        DispatchQueue.main.async() {
//                            self.navigationItem.prompt = "Logged in as \"\(self.identity)\""
                            
                        }
                    }
            } else {
                print("Error retrieving token: \(error.debugDescription)")
            }
            
        }
    }
    
    
    func logout() {
        if let client = client {
            client.delegate = nil
            client.shutdown()
            self.client = nil
        }
    }
    
    // MARK: Keyboard Dodging Logic
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = keyboardRect.height + 10
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        self.scrollToBottomMessage()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.bottomConstraint.constant = 20
            self.view.layoutIfNeeded()
        })
    }
    
    // MARK: UI Logic
    
    // Dismiss keyboard if container view is tapped
    @IBAction func viewTapped(_ sender: Any) {
        self.textField.resignFirstResponder()
    }
    // Scroll to bottom of table view for messages
    func scrollToBottomMessage() {
        if self.messages.count == 0 {
            return
        }
        let bottomMessageIndex = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    
    
    @IBAction func pickImageAction(_ sender: Any) {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pickDocumentAction(_ sender: Any) {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.text", "com.microsoft.word.doc","org.openxmlformats.wordprocessingml.document", "com.adobe.pdf"], in: UIDocumentPickerMode.open)
//        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.text"], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    
    @IBAction func reloadTableView(_ sender: Any) {
        tableView.reloadData()
    }
    
    @IBAction func sendAction(_ sender: Any) {
        sendImage()
        self.previewImageView.isHidden = true
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.previewImageView.isHidden = true
    }
    
    func sendImage() {
        if previewImage.image != nil {
            let imageData = UIImagePNGRepresentation(pickedImage)
            self.pickedImage = nil
            // Prepare the upload stream and parameters
            let messageOptions = TCHMessageOptions()
            let inputStream = InputStream(data: imageData!)
            messageOptions.withMediaStream(inputStream,
                                           contentType: "image/png",
                                           defaultFilename: "\(randomString(length: 5)).png",
                onStarted: {
                    // Called when upload of media begins.
                    print("Media upload started")
            },
                onProgress: { (bytes) in
                    // Called as upload progresses, with the current byte count.
                    print("Media upload progress: \(bytes)")
            }) { (mediaSid) in
                // Called when upload is completed, with the new mediaSid if successful.
                // Full failure details will be provided through sendMessage's completion.
                print("Media upload completed")
            }

            // Trigger the sending of the message.
            self.generalChannel?.messages?.sendMessage(with: messageOptions,
                                                       completion: { (result, message) in
                                                        
                                                        if !result.isSuccessful() {
                                                            print("Creation failed: \(String(describing: result.error))")
                                                        } else {
                                                            print("Creation successful")
                                                        }
            })
        }
       
    }
    
}

// MARK: Twilio Chat Delegate
extension ChatViewController: TwilioChatClientDelegate {
        
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == .completed {
            // Join (or create) the general channel
            let defaultChannel = "connectedtruckstest"
            if let channelsList = client.channelsList() {
                print("channelsList \(String(describing: channelsList.subscribedChannels()[1].messages))")
                
                channelsList.subscribedChannels()[1].messages?.getAfter(0, withCount: 100, completion: {result, historyMessages in
                    print("messages \(String(describing: historyMessages))")
//                    messages.append(message)
                    if let messagesHistory = historyMessages {
                        for message in messagesHistory {
                            
//                            if message.hasMedia() {
//
//                                // Set up output stream for media content
//                                let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
//                                print("tempFilename \(tempFilename)")
//
//                                let fileManager = FileManager.default
//                                if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
//                                    print("FILE AVAILABLE")
//
//                                } else {
//                                    print("FILE NOT AVAILABLE")
//                                    let outputStream = OutputStream(toFileAtPath: tempFilename, append: false)
//
//                                    // Request the start of the download
//                                    if let outputStream = outputStream {
//                                        message.getMediaWith(outputStream,
//                                                             onStarted: {
//                                                                // Called when download of media begins.
//                                        },
//                                                             onProgress: { (bytes) in
//                                                                // Called as download progresses, with the current byte count.
//                                        },
//                                                             onCompleted: { (mediaSid) in
//                                                                // Called when download is completed, with the new mediaSid if successful.
//                                                                // Full failure details will be provided through the completion block below.
//
//                                        }) { (result) in
//                                            if !result.isSuccessful() {
//                                                print("Download failed: \(String(describing: result.error))")
//                                            } else {
//                                                print("Download successful \(String(describing: UIImage(contentsOfFile: tempFilename)))")
//
//                                            }
//                                        }
//                                    }
//
//                                }
//
//
//
//                            }
//                            channelsList.subscribedChannels()[1].messages?.remove(message, completion: nil)
                            self.messages.append(message)

                        }
                        self.tableView.reloadData()
                    }

                })

                channelsList.channel(withSidOrUniqueName: defaultChannel, completion: { (result, channel) in
                    if let channel = channel {
                        self.generalChannel = channel
                        
                        channel.join(completion: { result in
                            print("Channel joined with result \(result)")
                            self.tableView.reloadData()
                            
                        })
                    } else {
                        // Create the general channel (for public use) if it hasn't been created yet
                        channelsList.createChannel(options: [TCHChannelOptionFriendlyName: "General Chat Channel", TCHChannelOptionType: TCHChannelType.public.rawValue], completion: { (result, channel) -> Void in
                                if result.isSuccessful() {
                                    self.generalChannel = channel
                                    self.generalChannel?.join(completion: { result in
                                        self.generalChannel?.setUniqueName(defaultChannel, completion: { result in
                                            print("channel unique name set")
                                        })
                                    })
                                }
                        })
                    }
                })
            }
        }
    }
    
    // Called whenever a channel we've joined receives a new message
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel,
                    messageAdded message: TCHMessage) {
        self.messages.append(message)
        
        if message.hasMedia() {
            print("mediaFilename: \(String(describing: message.mediaFilename)) (optional)")
            print("mediaSize: \(message.mediaSize)")

            // Set up output stream for media content
            let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
            let outputStream = OutputStream(toFileAtPath: tempFilename, append: false)

            // Request the start of the download
            if let outputStream = outputStream {
                message.getMediaWith(outputStream,
                                     onStarted: {
                                        // Called when download of media begins.
                },
                                     onProgress: { (bytes) in
                                        // Called as download progresses, with the current byte count.
                },
                                     onCompleted: { (mediaSid) in
                                        // Called when download is completed, with the new mediaSid if successful.
                                        // Full failure details will be provided through the completion block below.
                }) { (result) in
                    if !result.isSuccessful() {
                        print("Download failed: \(String(describing: result.error))")
                    } else {
                        print("Download successful")
                    }
                }
            }
        }
        
        self.tableView.reloadData()
        DispatchQueue.main.async() {
            if self.messages.count > 0 {
                self.scrollToBottomMessage()
            }
        }
    }
    
    //The target function
    @objc func imageDownloadBtnAction(_ sender: UIButton) { //<- needs `@objc`
        print("\(sender)")
        
        let message = self.messages[sender.tag]
        if message.author == identity {
            
            if message.hasMedia() {
                let indexPath = IndexPath(row: sender.tag, section: 0)
                let currentCell = tableView.cellForRow(at: indexPath) as! MessageImageTableViewCellSender
               
                if currentCell.messageImageView.image == UIImage.init(named: "camera") {
                    // Set up output stream for media content
                    let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
                    print("tempFilename \(tempFilename)")
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
                        print("FILE AVAILABLE")
                        currentCell.messageImageView.image = UIImage(contentsOfFile: tempFilename)
                        
                    } else {
                        
                        print("FILE NOT AVAILABLE")
                        let outputStream = OutputStream(toFileAtPath: tempFilename, append: false)
                        
                        // Request the start of the download
                        if let outputStream = outputStream {
                            message.getMediaWith(outputStream,
                                                 onStarted: {
                                                    // Called when download of media begins.
                            },
                                                 onProgress: { (bytes) in
                                                    // Called as download progresses, with the current byte count.
                            },
                                                 onCompleted: { (mediaSid) in
                                                    // Called when download is completed, with the new mediaSid if successful.
                                                    // Full failure details will be provided through the completion block below.
                                                    
                            }) { (result) in
                                if !result.isSuccessful() {
                                    print("Download failed: \(String(describing: result.error))")
                                } else {
                                    print("Download successful \(String(describing: UIImage(contentsOfFile: tempFilename)))")
                                    currentCell.messageImageView.image = UIImage(contentsOfFile: tempFilename)
                                    
                                }
                            }
                        }
                        
                    }
                } else {
                    
                    let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
                    print("tempFilename \(tempFilename)")
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
                        print("FILE AVAILABLE")
                        previewImageView.isHidden = false
                        previewImage.image = UIImage(contentsOfFile: tempFilename)
                    }
               
                }
            }
        } else {
            if message.hasMedia() {
                let indexPath = IndexPath(row: sender.tag, section: 0)
                let currentCell = tableView.cellForRow(at: indexPath) as! MessageImageTableViewCell
                
                if currentCell.messageImageView.image == UIImage.init(named: "camera") {
                    // Set up output stream for media content
                    let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
                    print("tempFilename \(tempFilename)")
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
                        print("FILE AVAILABLE")
                        currentCell.messageImageView.image = UIImage(contentsOfFile: tempFilename)
                        
                    } else {
                        
                        print("FILE NOT AVAILABLE")
                        let outputStream = OutputStream(toFileAtPath: tempFilename, append: false)
                        
                        // Request the start of the download
                        if let outputStream = outputStream {
                            message.getMediaWith(outputStream,
                                                 onStarted: {
                                                    // Called when download of media begins.
                            },
                                                 onProgress: { (bytes) in
                                                    // Called as download progresses, with the current byte count.
                            },
                                                 onCompleted: { (mediaSid) in
                                                    // Called when download is completed, with the new mediaSid if successful.
                                                    // Full failure details will be provided through the completion block below.
                                                    
                            }) { (result) in
                                if !result.isSuccessful() {
                                    print("Download failed: \(String(describing: result.error))")
                                } else {
                                    print("Download successful \(String(describing: UIImage(contentsOfFile: tempFilename)))")
                                    currentCell.messageImageView.image = UIImage(contentsOfFile: tempFilename)
                                    
                                }
                            }
                        }
                        
                    }
                } else {
                    
                    let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
                    print("tempFilename \(tempFilename)")
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
                        print("FILE AVAILABLE")
                        previewImageView.isHidden = false
                        previewImage.image = UIImage(contentsOfFile: tempFilename)

                    }
                    
                }
            }
        }
    }
}

// MARK: UITextField Delegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      
 
        
        // The data for the image you would like to send
//        let data = Data()
        
            if let messages = self.generalChannel?.messages {
                let messageOptions = TCHMessageOptions().withBody(textField.text!)
                print("messageOptions \(messageOptions)")
                messages.sendMessage(with: messageOptions, completion: { (result, message) in
                    print("result \(result)")
                    print("message \(String(describing: message))")
                    textField.text = ""
                    textField.resignFirstResponder()
                })
            }
  
        return true
    }
    
    
}


// MARK: UITableViewDataSource Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = self.messages[indexPath.row]
        
        if message.hasMedia() == false {
            return UITableViewAutomaticDimension
        }
//        let font = UIFont(name: "Helvetica Neue", size: 17.0)
//
//        let height = heightForView(text: message.body!, font: font!, width: view.frame.width - 20)

        return 230
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = self.messages[indexPath.row]
        
        if message.hasMedia() == false {
            return 50
        }
        
        return 230
    }
    // Return number of rows in the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    
    // Create table view rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            let message = self.messages[indexPath.row]
            if message.author == identity {
                if message.hasMedia() {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MessageImageCellSender", for: indexPath) as! MessageImageTableViewCellSender
                    cell.messageImageView.image = UIImage.init(named: "camera")

                    cell.imageDownloadBtn.addTarget(self, action: #selector(self.imageDownloadBtnAction(_:)), for: .touchUpInside) //<- use `#selector(...)`
                    cell.imageDownloadBtn.tag = indexPath.row

                    print("mediaFilename: \(String(describing: message.mediaFilename)) (optional)")
                    print("mediaSize: \(message.mediaSize)")

                    // Set up output stream for media content
                    let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
                    print("tempFilename \(tempFilename)")

                        let fileManager = FileManager.default
                        if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
                            print("FILE AVAILABLE")
                            cell.messageImageView.image = UIImage(contentsOfFile: tempFilename)
                        }

                
                    cell.selectionStyle = .none
                    return cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCellSender", for: indexPath) as! MessageTableViewCellSender
                    
                    // Set table cell values
                    cell.messageTextLbl?.text = message.body
                    
                    cell.selectionStyle = .none
                    return cell
                    
                }
            } else {
                if message.hasMedia() {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MessageImageCellReceiver", for: indexPath) as! MessageImageTableViewCell
                    cell.messageImageView.image = UIImage.init(named: "camera")

                    cell.imageDownloadBtn.addTarget(self, action: #selector(self.imageDownloadBtnAction(_:)), for: .touchUpInside) //<- use `#selector(...)`
                    cell.imageDownloadBtn.tag = indexPath.row
                    
                    print("mediaFilename: \(String(describing: message.mediaFilename)) (optional)")
                    print("mediaSize: \(message.mediaSize)")
                    
                    // Set up output stream for media content
                    let tempFilename = (NSTemporaryDirectory() as NSString).appendingPathComponent(message.mediaFilename ?? "file.dat")
                    print("tempFilename \(tempFilename)")
                    
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: tempFilename) && UIImage(contentsOfFile: tempFilename) != nil {
                        print("FILE AVAILABLE")
                        cell.messageImageView.image = UIImage(contentsOfFile: tempFilename)
                    }

                    
                    cell.selectionStyle = .none
                    return cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCellReceiver", for: indexPath) as! MessageTableViewCell
                    
                    // Set table cell values
                    cell.messageTextLbl?.text = message.body
                    
                    cell.selectionStyle = .none
                    return cell
                    
                }
            }
            
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
       
    }
}


extension ChatViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker:
        UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            pickedImage = image
            previewImageView.isHidden = false
            previewImage.image = pickedImage

        }
        else{
            print("Something went wrong")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
}


func randomString(length : Int) -> String {
    let charSet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters)
    let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: charSet) as! [Character]
    let array = shuffled.prefix(length)
    return String(array)
}



extension ChatViewController: ImageSelectionDelegate {
    func imageSelected(pickedImage: UIImage) {
            let imageData = UIImagePNGRepresentation(pickedImage)
            self.pickedImage = nil
            // Prepare the upload stream and parameters
            let messageOptions = TCHMessageOptions()
            let inputStream = InputStream(data: imageData!)
            messageOptions.withMediaStream(inputStream,
                                           contentType: "image/png",
                                           defaultFilename: "\(randomString(length: 10)).png",
                onStarted: {
                    // Called when upload of media begins.
                    print("Media upload started")
            },
                onProgress: { (bytes) in
                    // Called as upload progresses, with the current byte count.
                    print("Media upload progress: \(bytes)")
            }) { (mediaSid) in
                // Called when upload is completed, with the new mediaSid if successful.
                // Full failure details will be provided through sendMessage's completion.
                print("Media upload completed")
            }
            
            // Trigger the sending of the message.
            self.generalChannel?.messages?.sendMessage(with: messageOptions,
                                                       completion: { (result, message) in
                                                        
                                                        if !result.isSuccessful() {
                                                            print("Creation failed: \(String(describing: result.error))")
                                                        } else {
                                                            print("Creation successful")
                                                        }
            })
    }
}


//extension ChatViewController: UIDocumentMenuDelegate,UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
//        
//    }
//}


// MARK: - UIDocumentPickerDelegate Methods
extension ChatViewController: UIDocumentPickerDelegate
{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.open {
            pickedDocUrl = url
            if pickedDocUrl != nil {
                
                do {
                    let fileData = try Data(contentsOf: pickedDocUrl)
                    // Prepare the upload stream and parameters
                    let messageOptions = TCHMessageOptions()
                    let inputStream = InputStream(data: fileData)
                    messageOptions.withMediaStream(inputStream,
                                                   contentType: "application/pdf",
                                                   defaultFilename: pickedDocUrl.lastPathComponent,
                        onStarted: {
                            // Called when upload of media begins.
                            print("Media upload started")
                    },
                        onProgress: { (bytes) in
                            // Called as upload progresses, with the current byte count.
                            print("Media upload progress: \(bytes)")
                    }) { (mediaSid) in
                        // Called when upload is completed, with the new mediaSid if successful.
                        // Full failure details will be provided through sendMessage's completion.
                        print("Media upload completed")
                    }
                    
                    // Trigger the sending of the message.
                    self.generalChannel?.messages?.sendMessage(with: messageOptions,
                                                               completion: { (result, message) in
                                                                self.pickedDocUrl = nil

                                                                if !result.isSuccessful() {
                                                                    print("Creation failed: \(String(describing: result.error))")
                                                                } else {
                                                                    print("Creation successful")
                                                                }
                    })
                } catch {
                    print("Unable to load data: \(error)")
                }
                
                
            }
            // This is what it should be
        }
    }
  
}
