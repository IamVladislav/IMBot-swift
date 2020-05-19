//
//  base_bot.swift
//  Testing bot
//
//  Created by v.metel on 08.03.2020.
//  Copyright © 2020 v.metel. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol QueryString {
    var queryString: String { get }
}

extension String: QueryString {
    var queryString: String {
        return self
    }
}

extension Array: QueryString {
    var queryString: String {
        var result: String = ""
        if self is Array<Bot.BotButton> || self is Array<Array<Bot.BotButton>> {
            result = "["
        }
        for element in self {
            switch element {
            case is Bot.Actions: result += (element as! Bot.Actions).rawValue + ","
            case is String: result += (element as! String) + ","
            case is Array<Bot.BotButton>: result += (element as! Array<Bot.BotButton>).queryString + ","
            case is Bot.BotButton: result += (element as! Bot.BotButton).queryString + ","
            default: break
            }
        }
        if !result.isEmpty {
            result.removeLast()
        }
        if self is Array<Bot.BotButton> || self is Array<Array<Bot.BotButton>> {
            result += "]"
        }
        return result
    }
}

public class Bot {
    let baseUrl: String
    let token: String
    var lastEventId: Int64
    var lastRequestID: Int64
    let pollTime: Int
    let queue = DispatchQueue.global(qos: .background)
    var log: Log?
    
    public init(baseUrl: String = "https://api.icq.net/bot/v1", token: String, lastEventId: Int64 = 0, pollTime: Int = 10, botName: String = "ApiTestBot", enableLog: Bool = true) {
        self.baseUrl = baseUrl
        self.token = token
        self.lastEventId = lastEventId
        self.pollTime = pollTime
        
        if enableLog {
            log = Log(botName: botName)
        }
        
        lastRequestID = 0
    }
    
    public func getLastRequestID() -> Int64 {
        lastRequestID+=1
        return lastRequestID
    }
    
    enum BotRequests: String {
        case selfGet = "/self/get"
        case messagesSendText = "/messages/sendText"
        case messagesSendFile = "/messages/sendFile"
        case messagesSendVoice = "/messages/sendVoice"
        case messagesEditText = "/messages/editText"
        case messagesDeleteMessages = "/messages/deleteMessages"
        case messagesAnswerCallbackQuery = "/messages/answerCallbackQuery"
        case chatSendActions = "/chats/sendActions"
        case chatGetInfo = "/chats/getInfo"
        case chatGetAdmins = "/chats/getAdmins"
        case chatGetMembers = "/chats/getMembers"
        case chatGetBlockedUsers = "/chats/getBlockedUsers"
        case chatGetPendingUsers = "/chats/getPendingUsers"
        case chatBlockUser = "/chats/blockUser"
        case chatUnblockUser = "/chats/unblockUser"
        case chatResolvePending = "/chats/resolvePending"
        case chatSetTitle = "/chats/setTitle"
        case chatSetAbout = "/chats/setAbout"
        case chatSetRules = "/chats/setRules"
        case chatPinMessage = "/chats/pinMessage"
        case chatUnpinMessage = "/chats/unpinMessage"
        case filesGetInfo = "/files/getInfo"
        case eventsGet = "/events/get"
    }
    
    public enum Actions:String {
        case typing = "typing"
        case looking = "looking"
    }
    
    public struct BotButton: QueryString {
        public init(text: String, url: String?) {
            self.text = text
            self.url = url
            self.callbackData = nil
        }
        
        public init(text: String, callbackData: String?) {
            self.text = text
            self.url = nil
            self.callbackData = callbackData
        }
        
        var text: String
        var url: String?
        var callbackData: String?
        
        var queryString: String {
            var result: String = ""
            result += "{\"text\":" + "\"" + text.queryString + "\"" + ","
            if url != nil {
                result += "\"url\":" + "\"" + url!.queryString + "\"" + ","
            }
            if callbackData != nil {
                result += "\"callbackData\":" + "\"" + callbackData!.queryString + "\"" + ","
            }
            result.removeLast()
            result += "}"
            return result
        }
    }
    
    struct GetRequest: URLRequestConvertible {
        let baseUrl: String
        let urlRequest: BotRequests
        let query: Dictionary<String, QueryString>
        let requestID: Int64
        let log: Log?
        
        init(baseUrl: String, urlRequest: BotRequests, query: Dictionary<String, QueryString>, requestID: Int64, log: Log? = nil) {
            self.baseUrl = baseUrl
            self.urlRequest = urlRequest
            self.query = query
            self.requestID = requestID
            self.log = log
        }
        
        func asURLRequest() throws -> URLRequest {
            var result_url = self.baseUrl + self.urlRequest.rawValue
            guard !query.isEmpty else {
                return try! URLRequest.init(url: result_url, method: .get)
            }
            result_url += "?"
            for param in query {
                result_url += param.key + "=" + param.value.queryString + "&"
            }
            result_url.removeLast()
            log?.requestData.updateValue(result_url, forKey: requestID)
            return try! URLRequest.init(url: result_url, method: .get)
        }
    }
    
    struct UploadRequest: URLConvertible {
        let baseUrl: String
        let urlRequest: BotRequests
        let query: Dictionary<String, QueryString>
        let requestID: Int64
        let log: Log?
        
        init(baseUrl: String, urlRequest: BotRequests, query: Dictionary<String, QueryString>, requestID: Int64, log: Log? = nil) {
            self.baseUrl = baseUrl
            self.urlRequest = urlRequest
            self.query = query
            self.requestID = requestID
            self.log = log
        }
        
        func asURL() throws -> URL {
            var result_url = self.baseUrl + self.urlRequest.rawValue
            guard !query.isEmpty else {
                return try! result_url.asURL()
            }
            result_url += "?"
            for param in query {
                result_url += param.key + "=" + param.value.queryString + "&"
            }
            result_url.removeLast()
            log?.requestData.updateValue(result_url, forKey: requestID)
            return try! result_url.asURL()
        }
    }
    
    public func selfGet(requestID: Int64) {
        let query = ["token": token]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .selfGet
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSelfGetComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func sendText(chatId: String, text: String, replyMsgId: Array<String>? = nil, forwardChatId: String? = nil, forwardMsgId: Array<String>? = nil, inlineKeyboardMarkup: Array<Array<BotButton>>? = nil, requestID: Int64) {
        var query = ["token": token, "chatId":chatId, "text":text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!]
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (inlineKeyboardMarkup != nil) {
            query.updateValue(inlineKeyboardMarkup!.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "inlineKeyboardMarkup")
        }
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .messagesSendText
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSendTextComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func sendFile(chatId: String, fileId: String, caption: String? = nil, replyMsgId: Array<String>? = nil, forwardChatId: String? = nil, forwardMsgId: Array<String>? = nil, inlineKeyboardMarkup: Array<Array<BotButton>>? = nil, requestID: Int64) {
        var query = ["token": token, "chatId":chatId, "fileId": fileId]
        if (caption != nil) {
            query.updateValue(caption!, forKey: "caption")
        }
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (inlineKeyboardMarkup != nil) {
            query.updateValue(inlineKeyboardMarkup!.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "inlineKeyboardMarkup")
        }
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .messagesSendFile
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSendFileComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func sendFile(chatId: String, fileURL: URL,caption: String? = nil, replyMsgId: Array<String>? = nil, forwardChatId: String? = nil, forwardMsgId: Array<String>? = nil, inlineKeyboardMarkup: Array<Array<BotButton>>? = nil, requestID: Int64) {
        var query = ["token": token, "chatId":chatId]
        if (caption != nil) {
            query.updateValue(caption!, forKey: "caption")
        }
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (inlineKeyboardMarkup != nil) {
            query.updateValue(inlineKeyboardMarkup!.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "inlineKeyboardMarkup")
        }
        AF.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(fileURL, withName: "file")
        }, to: UploadRequest(baseUrl: self.baseUrl, urlRequest: .messagesSendFile, query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSendFileComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func sendVoice(chatId: String, fileId: String, replyMsgId: Array<String>? = nil, forwardChatId: String? = nil, forwardMsgId: Array<String>? = nil, inlineKeyboardMarkup: Array<Array<BotButton>>? = nil, requestID: Int64) {
        var query = ["token": token, "chatId":chatId, "fileId": fileId]
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (inlineKeyboardMarkup != nil) {
            query.updateValue(inlineKeyboardMarkup!.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "inlineKeyboardMarkup")
        }
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .messagesSendVoice
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSendVoiceComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func sendVoice(chatId: String, fileURL: URL, replyMsgId: Array<String>? = nil, forwardChatId: String? = nil, forwardMsgId: Array<String>? = nil, inlineKeyboardMarkup: Array<Array<BotButton>>? = nil, requestID: Int64) {
        var query = ["token": token, "chatId":chatId]
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (replyMsgId != nil) {
            query.updateValue(replyMsgId!.queryString, forKey: "replyMsgId")
        }
        if (forwardChatId != nil) {
            query.updateValue(forwardChatId!.queryString, forKey: "forwardChatId")
        }
        if (forwardMsgId != nil) {
            query.updateValue(forwardMsgId!.queryString, forKey: "forwardMsgId")
        }
        if (inlineKeyboardMarkup != nil) {
            query.updateValue(inlineKeyboardMarkup!.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "inlineKeyboardMarkup")
        }
        AF.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(fileURL, withName: "file")
        }, to: UploadRequest(baseUrl: self.baseUrl, urlRequest: .messagesSendVoice, query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSendVoiceComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func editText(chatId: String, text: String, msgId: String, inlineKeyboardMarkup: Array<Array<BotButton>>? = nil, requestID: Int64) {
        var query = ["token": token, "chatId": chatId, "text": text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, "msgId": msgId]
        if (inlineKeyboardMarkup != nil) {
            query.updateValue(inlineKeyboardMarkup!.queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "inlineKeyboardMarkup")
        }
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .messagesEditText
        , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onEditTextComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func deleteMessages(chatId: String, msgId: Array<String>, requestID: Int64) {
        let query = ["token": token, "chatId": chatId, "msgId": msgId.queryString]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .messagesDeleteMessages
        , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onDeleteMessagesComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func answerCallbackQuery(queryId: String, text: String, showAlert: Bool? = nil, url: String? = nil, requestID: Int64) {
        var query = ["token": token, "queryId": queryId, "text": text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!]
        if showAlert != nil {
            query.updateValue(showAlert!.description, forKey: "showAlert")
        }
        if url != nil {
            query.updateValue(url!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!, forKey: "url")
        }
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .messagesAnswerCallbackQuery
        , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onAnswerCallbackQueryComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func sendActions(chatId: String, actions: [Actions], requestID: Int64) {
        let query = ["token": token, "chatId": chatId, "actions": actions] as [String : QueryString]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatSendActions
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSendActionsComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func getInfo(chatId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatGetInfo
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onGetInfoComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func getAdmins(chatId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatGetAdmins
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onGetAdminsComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func getMembers(chatId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatGetMembers
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onGetMembersComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func getBlockedUsers(chatId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatGetBlockedUsers
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onGetBlockedUsersComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func getPendingUsers(chatId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatGetPendingUsers
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onGetPendingUsersComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func blockUser(chatId: String, userId: String, delLastMessages: Bool = false, requestID: Int64) {
        let query = ["token": token, "chatId": chatId, "userId": userId, "delLastMessages": delLastMessages.description]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatBlockUser
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onBlockUsersComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func unblockUser(chatId: String, userId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId, "userId": userId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatUnblockUser
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onUnblockUsersComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func setTitle(chatId: String, title: String, requestID: Int64) {
        let query = ["token": token, "chatId":chatId, "title":title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatSetTitle
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSetTitleComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func setAbout(chatId: String, about: String, requestID: Int64) {
        let query = ["token": token, "chatId":chatId, "about":about.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatSetAbout
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSetAboutComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func setRules(chatId: String, rules: String, requestID: Int64) {
        let query = ["token": token, "chatId":chatId, "rules":rules.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatSetRules
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onSetRulesComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func pinMessage(chatId: String, msgId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId, "msgId": msgId]
        let localLastRequestID = getLastRequestID()
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatPinMessage
            , query: query, requestID: localLastRequestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: localLastRequestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onPinMessageComplete, object: body, userInfo: ["requestID": localLastRequestID])
            case .failure(let error): print(error)
            }
        }
    }

    public func unpinMessage(chatId: String, msgId: String, requestID: Int64) {
        let query = ["token": token, "chatId": chatId, "msgId": msgId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .chatUnpinMessage
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onUnpinMessageComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func getFilesGetInfo(fileId: String, requestID: Int64) {
        let query = ["token": token, "fileId": fileId]
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .filesGetInfo
            , query: query, requestID: requestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: requestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onFilesGetInfoComplete, object: body, userInfo: ["requestID": requestID])
            case .failure(let error): print(error)
            }
        }
    }
    
    public func eventsGet() {
        let query = ["token": token, "lastEventId": lastEventId.description, "pollTime": pollTime.description]
        let localLastRequestID = getLastRequestID()
        AF.request(GetRequest(baseUrl: self.baseUrl, urlRequest: .eventsGet
            , query: query, requestID: localLastRequestID, log: self.log)).responseJSON(queue: self.queue){response in
            self.log?.networkLog(response.description, requestID: localLastRequestID)
            switch response.result {
            case .success(let body): NotificationCenter.default.post(name: .onEventsGetComplete, object: body, userInfo: ["key": "Value"])
            case .failure(let error): print(error)
            }
        }
    }
}

extension Notification.Name {
    static let onSelfGetComplete = Notification.Name("onSelfGetComplete")
    static let onSendTextComplete = Notification.Name("onSendTextComplete")
    static let onSendFileComplete = Notification.Name("onSendFileComplete")
    static let onSendVoiceComplete = Notification.Name("onSendVoiceComplete")
    static let onEditTextComplete = Notification.Name("onEditTextComplete")
    static let onDeleteMessagesComplete = Notification.Name("onDeleteMessagesComplete")
    static let onAnswerCallbackQueryComplete = Notification.Name("onAnswerCallbackQueryComplete")
    static let onSendActionsComplete = Notification.Name("onSendActionsComplete")
    static let onGetInfoComplete = Notification.Name("onGetInfoComplete")
    static let onGetAdminsComplete = Notification.Name("onGetAdminsComplete")
    static let onGetMembersComplete = Notification.Name("onGetMembersComplete")
    static let onGetBlockedUsersComplete = Notification.Name("onGetBlockedUsersComplete")
    static let onGetPendingUsersComplete = Notification.Name("onGetPendingUsersComplete")
    static let onBlockUsersComplete = Notification.Name("onBlockUsersComplete")
    static let onUnblockUsersComplete = Notification.Name("onUnblockUsersComplete")
    static let onSetTitleComplete = Notification.Name("onSetTitleComplete")
    static let onSetAboutComplete = Notification.Name("onSetAboutComplete")
    static let onSetRulesComplete = Notification.Name("onSetRulesComplete")
    static let onPinMessageComplete = Notification.Name("onPinMessageComplete")
    static let onUnpinMessageComplete = Notification.Name("onUnpinMessageComplete")
    static let onFilesGetInfoComplete = Notification.Name("onFilesGetInfoComplete")
    static let onEventsGetComplete = Notification.Name("onEventsGetComplete")
}

public class BotDelegate{
    unowned var baseBot: Bot
    
    public var eventQueue = Array<Any?>()
    
    public var requestDictionary = Dictionary<Int64, Any>()
    let maxRequestDictionaryCount: Int64 = 100
    var lastClearedRequestId: Int64 = 0
    
    public var needNewRequest: Bool = true
    
    func clearRequestDictionary() {
        if requestDictionary.count > maxRequestDictionaryCount {
            for requestId in lastClearedRequestId...lastClearedRequestId + maxRequestDictionaryCount {
                requestDictionary.removeValue(forKey: requestId)
            }
            lastClearedRequestId = lastClearedRequestId + maxRequestDictionaryCount
        }
    }
    
    public init(bot: Bot) {
        baseBot = bot
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSelfGetComplete, object: nil, queue: nil, using: onSelfGetNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSendTextComplete, object: nil, queue: nil, using: onSendTextNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSendFileComplete, object: nil, queue: nil, using: onSendFileNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSendVoiceComplete, object: nil, queue: nil, using: onSendVoiceNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onEditTextComplete, object: nil, queue: nil, using: onEditTextNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onDeleteMessagesComplete, object: nil, queue: nil, using: onDeleteMessagesNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onAnswerCallbackQueryComplete, object: nil, queue: nil, using: onAnswerCallbackQueryNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSendActionsComplete, object: nil, queue: nil, using: onSendActionsNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onGetInfoComplete, object: nil, queue: nil, using: onGetInfoNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onGetAdminsComplete, object: nil, queue: nil, using: onGetAdminsNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onGetMembersComplete, object: nil, queue: nil, using: onGetMembersNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onGetBlockedUsersComplete, object: nil, queue: nil, using: onGetBlockedUsersNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onGetPendingUsersComplete, object: nil, queue: nil, using: onGetPendingUsersNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onBlockUsersComplete, object: nil, queue: nil, using: onBlockUsersNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onUnblockUsersComplete, object: nil, queue: nil, using: onUnblockUsersNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSetTitleComplete, object: nil, queue: nil, using: onSetTitleNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSetAboutComplete, object: nil, queue: nil, using: onSetAboutNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onSetRulesComplete, object: nil, queue: nil, using: onSetRulesNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onPinMessageComplete, object: nil, queue: nil, using: onPinMessageNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onUnpinMessageComplete, object: nil, queue: nil, using: onUnpinMessageNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onFilesGetInfoComplete, object: nil, queue: nil, using: onFilesGetInfoNotify)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.onEventsGetComplete, object: nil, queue: nil, using: onEventsGetNotify)
    }
    
    func onSelfGetNotify(_ notification: Notification) {
        guard let selfInfo_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(getInfoParse(JSON(selfInfo_json)), forKey: requestID as! Int64)
    }
    
    func onSendTextNotify(_ notification: Notification) {
        guard let sendText_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(sendTextParse(JSON(sendText_json)), forKey: requestID as! Int64)
    }
    
    func onSendFileNotify(_ notification: Notification) {
        guard let sendFile_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(sendFileParse(JSON(sendFile_json)), forKey: requestID as! Int64)
    }
    
    func onSendVoiceNotify(_ notification: Notification) {
        guard let sendFile_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(sendFileParse(JSON(sendFile_json)), forKey: requestID as! Int64)
    }
    
    func onEditTextNotify(_ notification: Notification) {
    }
    
    func onDeleteMessagesNotify(_ notification: Notification) {
    }
    
    func onAnswerCallbackQueryNotify(_ notification: Notification) {
    }
    
    func onSendActionsNotify(_ notification: Notification) {
    }
    
    func onGetInfoNotify(_ notification: Notification) {
        guard let getInfo_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(getInfoParse(JSON(getInfo_json)), forKey: requestID as! Int64)
    }
    
    func onGetAdminsNotify(_ notification: Notification) {
        guard let getAdmins_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(getAdminsParse(JSON(getAdmins_json)), forKey: requestID as! Int64)
    }
    
    func onGetMembersNotify(_ notification: Notification) {
        guard let getMembers_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(getMembersParse(JSON(getMembers_json)), forKey: requestID as! Int64)
    }
    
    func onGetBlockedUsersNotify(_ notification: Notification) {
        guard let getBlockedUsers_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(getUsersParse(JSON(getBlockedUsers_json)), forKey: requestID as! Int64)
    }
    
    func onGetPendingUsersNotify(_ notification: Notification) {
        guard let getBlockedUsers_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(getUsersParse(JSON(getBlockedUsers_json)), forKey: requestID as! Int64)
    }
    
    func onBlockUsersNotify(_ notification: Notification) {
    }
    
    func onUnblockUsersNotify(_ notification: Notification) {
    }
    
    func onSetTitleNotify(_ notification: Notification) {
    }
    
    func onSetAboutNotify(_ notification: Notification) {
    }
    
    func onSetRulesNotify(_ notification: Notification) {
    }
    
    func onPinMessageNotify(_ notification: Notification) {
    }
    
    func onUnpinMessageNotify(_ notification: Notification) {
    }
    
    func onFilesGetInfoNotify(_ notification: Notification) {
        guard let filesGetInfo_json =  notification.object else {return}
        guard let requestID = notification.userInfo?["requestID"] else {return}
        requestDictionary.updateValue(filesGetInfoParse(JSON(filesGetInfo_json)), forKey: requestID as! Int64)
    }
    
    func onEventsGetNotify(_ notification: Notification) {
        guard let events =  notification.object else {return}
        for event in JSON(events)["events"].arrayValue {
            let (eventId, parsedEvent) = fetchParse(event)
            self.eventQueue.append(parsedEvent)
            if baseBot.lastEventId < (eventId ?? 0) - 1 {
                baseBot.lastEventId = (eventId ?? 0) - 1
            }
        }
        if !JSON(events)["events"].arrayValue.isEmpty {
            baseBot.lastEventId+=1
        }
        needNewRequest = true
        
        clearRequestDictionary()
    }
}
