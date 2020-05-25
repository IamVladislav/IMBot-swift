import Foundation

public extension Array {
    mutating func popFirst() -> Element? {
        if !self.isEmpty {
            let returnedElement = self.first
            self.removeFirst()
            return returnedElement
        }
        return nil
    }
}

public class IMBotExample {
    var lastEventId: Int64
    let bot: Bot
    let delegate: BotDelegate
    
    public init(token: String, lastEventId: Int64 = 0) {
        self.lastEventId = lastEventId
        self.bot = Bot(token: token, lastEventId: lastEventId, enableLog: true)
        self.delegate = BotDelegate(bot: bot)
        
        start()
    }
    
    func start() {
        while(true) {
            if(delegate.needNewRequest) {
                delegate.needNewRequest = false
                bot.eventsGet()
            }
            if (delegate.eventQueue.isEmpty && logicQueue.isEmpty)
            {
                usleep(10000)
            }
            else {
                if (delegate.eventQueue.first is NewMessage) {
                    let currentMessage = delegate.eventQueue.popFirst() as! NewMessage
                    if (currentMessage.text == "/sendMessage") {
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I'm message!", requestID: bot.getLastRequestID())
                    }
                    else if currentMessage.text == "/sendButtons" {
                        let button1 = Bot.BotButton(text: "Toast button", callbackData: "toast")
                        let button2 = Bot.BotButton(text: "Alert button", callbackData: "alert")
                        let button3 = Bot.BotButton(text: "Internal url button", url: internalURL)
                        let button4 = Bot.BotButton(text: "External url button", url: externalURL)
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I'm message with buttons!", inlineKeyboardMarkup: [[button1, button2],[button3, button4]] , requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/replyMessage") {
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I'm reply on message!", replyMsgId: [currentMessage.msgId!] , requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/forwardMessage") {
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I'm forwarded message!", forwardChatId: currentMessage.chat!.chatId!, forwardMsgId: [currentMessage.msgId!], requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/sendPreloadedFile") {
                        bot.sendFile(chatId: currentMessage.chat!.chatId!, fileId: preloadedFileId, requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/sendPreloadedFileWithCaption") {
                        bot.sendFile(chatId: currentMessage.chat!.chatId!, fileId: preloadedFileId, caption: "I'm caption!", requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/replyMessageByFile") {
                        bot.sendFile(chatId: currentMessage.chat!.chatId!, fileId: preloadedFileId, replyMsgId: [currentMessage.msgId!], requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/forwardMessageByFile") {
                        bot.sendFile(chatId: currentMessage.chat!.chatId!, fileId: preloadedFileId, forwardChatId: currentMessage.chat!.chatId!, forwardMsgId: [currentMessage.msgId!], requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/sendPreloadedVoice") {
                        bot.sendVoice(chatId: currentMessage.chat!.chatId!, fileId: preloadedVoiceId, requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/replyMessageByVoice") {
                        bot.sendVoice(chatId: currentMessage.chat!.chatId!, fileId: preloadedVoiceId, replyMsgId: [currentMessage.msgId!], requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/forwardMessageByVoice") {
                        bot.sendVoice(chatId: currentMessage.chat!.chatId!, fileId: preloadedVoiceId, forwardChatId: currentMessage.chat!.chatId!, forwardMsgId: [currentMessage.msgId!], requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/sendFile") {
                        bot.sendFile(chatId: currentMessage.chat!.chatId!, fileURL: filePath, requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/sendVoice") {
                        bot.sendVoice(chatId: currentMessage.chat!.chatId!, fileURL: voicePath, requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/editMessage") {
                        let requestID = bot.getLastRequestID()
                        logicQueue.updateValue((.editResponse, currentMessage.chat!), forKey: requestID)
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I'm message for editing!", requestID: requestID)
                    }
                    else if (currentMessage.text == "/deleteMessage") {
                        let requestID = bot.getLastRequestID()
                        logicQueue.updateValue((.deleteResponse, currentMessage.chat!), forKey: requestID)
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I'm message for deleting!", requestID: requestID)
                    }
                    else if (currentMessage.text == "/getAdmins") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.adminsResponse, currentMessage.chat!), forKey: requestID)
                            bot.getAdmins(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/getMembers") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.membersResponse, currentMessage.chat!), forKey: requestID)
                            bot.getMembers(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/getBlockeds") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.blockedsResponse, currentMessage.chat!), forKey: requestID)
                            bot.getBlockedUsers(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                        }
                                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/getPendings") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.pendingsResponse, currentMessage.chat!), forKey: requestID)
                            bot.getPendingUsers(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/blockUser") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.blockResponse, currentMessage.chat!), forKey: requestID)
                            bot.getMembers(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/unblockUser") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.unblockResponse, currentMessage.chat!), forKey: requestID)
                            bot.getBlockedUsers(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/pinMessage") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            bot.pinMessage(chatId: currentMessage.chat!.chatId!, msgId: currentMessage.msgId!, requestID: bot.getLastRequestID())
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/unpinMessage") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            let requestID = bot.getLastRequestID()
                            logicQueue.updateValue((.unpinResponse, currentMessage.chat!), forKey: requestID)
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Message for unpinning!", requestID: requestID)
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/setTitle") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            bot.setTitle(chatId: currentMessage.chat!.chatId!, title: "Tittle added by bot.", requestID: bot.getLastRequestID())
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/setAbout") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            bot.setAbout(chatId: currentMessage.chat!.chatId!, about: "About added by bot.", requestID: bot.getLastRequestID())
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/setRules") {
                        if currentMessage.chat?.type == "channel" || currentMessage.chat?.type == "group" {
                            bot.setRules(chatId: currentMessage.chat!.chatId!, rules: "Rules added by bot.", requestID: bot.getLastRequestID())
                        }
                        else {
                            bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Command avalible only for group or channel!", requestID: bot.getLastRequestID())
                        }
                    }
                    else if (currentMessage.text == "/sendTyping") {
                        bot.sendActions(chatId: currentMessage.chat!.chatId!, actions: [Bot.Actions.typing], requestID: bot.getLastRequestID())
                    }
                    else if (currentMessage.text == "/getInfo") {
                        let requestID = bot.getLastRequestID()
                        logicQueue.updateValue((.chatInfoResponse, currentMessage.chat!), forKey: requestID)
                        bot.getInfo(chatId: currentMessage.chat!.chatId!, requestID: requestID)
                    }
                    else if (currentMessage.text == "/selfInfo") {
                        let requestID = bot.getLastRequestID()
                        logicQueue.updateValue((.selfInfoResponse, currentMessage.chat!), forKey: requestID)
                        bot.selfGet(requestID: requestID)
                    }
                    else if currentMessage.parts?[0].type == "file" || currentMessage.parts?[0].type == "sticker" || currentMessage.parts?[0].type == "voice" {
                         let requestID = bot.getLastRequestID()
                         logicQueue.updateValue((.getInfoResponse, currentMessage.chat!), forKey: requestID)
                         bot.getFilesGetInfo(fileId: (currentMessage.parts?[0].part as! FileParts).fileId!, requestID: requestID)
                    }
                    else {
                        bot.sendText(chatId: currentMessage.chat!.chatId!, text: help, requestID: bot.getLastRequestID())
                    }
                }
                else if delegate.eventQueue.first is EditedMessage {
                    let currentMessage = delegate.eventQueue.popFirst() as! EditedMessage
                    bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I see, that you edited message: \n" + currentMessage.msgId!, requestID: bot.getLastRequestID())
                }
                else if delegate.eventQueue.first is DeletedMessage {
                    let currentMessage = delegate.eventQueue.popFirst() as! DeletedMessage
                    bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I see, that you deleted message: \n" + currentMessage.msgId!, requestID: bot.getLastRequestID())
                }
                else if delegate.eventQueue.first is PinnedMessage {
                    let currentMessage = delegate.eventQueue.popFirst() as! PinnedMessage
                    bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I see pinned message: \n" + currentMessage.msgId!, requestID: bot.getLastRequestID())
                }
                else if delegate.eventQueue.first is UnpinnedMessage {
                    let currentMessage = delegate.eventQueue.popFirst() as! UnpinnedMessage
                    bot.sendText(chatId: currentMessage.chat!.chatId!, text: "I see unpinned message: \n"  + currentMessage.msgId!, requestID: bot.getLastRequestID())
                }
                else if delegate.eventQueue.first is NewChatMembers {
                    let currentMessage = delegate.eventQueue.popFirst() as! NewChatMembers
                    bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Glad to see you, " + (currentMessage.newMembers?.first?.firstName ?? "") + "!", requestID: bot.getLastRequestID())
                }
                else if delegate.eventQueue.first is LeftChatMembers {
                    let currentMessage = delegate.eventQueue.popFirst() as! LeftChatMembers
                    bot.sendText(chatId: currentMessage.chat!.chatId!, text: "Goodbay, " + (currentMessage.leftMembers?.first?.firstName ?? "") + "!", requestID: bot.getLastRequestID())
                }
                else if delegate.eventQueue.first is CallbackQuery {
                    let callback = delegate.eventQueue.popFirst() as! CallbackQuery
                    switch callback.callbackData {
                    case "toast": bot.answerCallbackQuery(queryId: callback.queryId!, text: "I'm toast!", requestID: bot.getLastRequestID())
                    case "alert": bot.answerCallbackQuery(queryId: callback.queryId!, text: "I'm alert!", showAlert: true, requestID: bot.getLastRequestID())
                    default: break
                    }
                }
                else {
                    let _ = delegate.eventQueue.popFirst()
                }
                if !logicQueue.isEmpty {
                    for (key, value) in logicQueue{
                        switch value {
                        case (.editResponse, _): if let response = delegate.requestDictionary[key] as? NewMessage {
                            bot.editText(chatId: (value.1 as! Chat).chatId!, text: "I'm edit this message!", msgId: response.msgId!, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.deleteResponse, _): if let response = delegate.requestDictionary[key] as? NewMessage {
                            bot.deleteMessages(chatId: (value.1 as! Chat).chatId!, msgId: [response.msgId!], requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.adminsResponse, _): if let response = delegate.requestDictionary[key] as? Array<Admin> {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.description, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.membersResponse, _): if let response = delegate.requestDictionary[key] as? Array<Member> {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.description, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.blockedsResponse, _): if let response = delegate.requestDictionary[key] as? Array<User> {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.description, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.pendingsResponse, _): if let response = delegate.requestDictionary[key] as? Array<User> {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.description, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.unpinResponse, _): if let response = delegate.requestDictionary[key] as? NewMessage {
                            bot.pinMessage(chatId: (value.1 as! Chat).chatId!, msgId: response.msgId!, requestID: bot.getLastRequestID())
                            bot.unpinMessage(chatId: (value.1 as! Chat).chatId!, msgId: response.msgId!, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.blockResponse, _): if let response = delegate.requestDictionary[key] as? Array<Member> {
                            for member in response {
                                if member.admin == nil  {
                                    bot.blockUser(chatId: (value.1 as! Chat).chatId!, userId: member.userID!, delLastMessages: true, requestID: bot.getLastRequestID())
                                    break
                                }
                            }
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.unblockResponse, _): if let response = delegate.requestDictionary[key] as? Array<User> {
                            for user in response {
                                bot.unblockUser(chatId: (value.1 as! Chat).chatId!, userId: user.userID!, requestID: bot.getLastRequestID())
                                break
                            }
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.chatInfoResponse, _): if let response = delegate.requestDictionary[key] as? ChatInfo {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.type!, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.selfInfoResponse, _): if let response = delegate.requestDictionary[key] as? ChatInfo {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.nick!, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        case (.getInfoResponse, _): if let response = delegate.requestDictionary[key] as? File {
                            bot.sendText(chatId: (value.1 as! Chat).chatId!, text: response.filename!, requestID: bot.getLastRequestID())
                            logicQueue.removeValue(forKey: key)
                        }
                        }
                    }
                }
            }
        }
    }
    
    enum Commands {
        case editResponse
        case deleteResponse
        
        case adminsResponse
        case membersResponse
        case blockedsResponse
        case pendingsResponse
        
        case unpinResponse
        case blockResponse
        case unblockResponse
        
        case chatInfoResponse
        case selfInfoResponse
        case getInfoResponse
    }

    let help: String = """
    Commands:
    /sendMessage
    /sendButtons
    /replyMessage
    /forwardMessage
    /sendPreloadedFile
    /sendPreloadedFileWithCaption
    /replyMessageByFile
    /forwardMessageByFile
    /sendPreloadedVoice
    /replyMessageByVoice
    /forwardMessageByVoice
    /sendFile
    /sendVoice
    /editMessage
    /deleteMessage
    /getAdmins
    /getMembers
    /getBlockeds
    /getPendings
    /blockUser
    /unblockUser
    /pinMessage
    /unpinMessage
    /setTitle
    /setAbout
    /setRules
    /sendTyping
    /getInfo
    /selfInfo

    fileInfo - send file, sticker or voice
    help - send any message
    """

    let preloadedFileId: String = "03Y0U000ArRHZAJrdJUUwN5ebc39d21be"
    let preloadedVoiceId: String = "I00041eF0kbnqVhhbLkp5I5ebc3a4f1be"

    let filePath = URL(fileURLWithPath: "ubnt.cer", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    let voicePath = URL(fileURLWithPath: "voice.aac", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)

    let internalURL: String = "https://icq.im/icq.com"
    let externalURL: String = "https://icq.com"
    
    var logicQueue = Dictionary<Int64, (Commands, Any)>()

}
