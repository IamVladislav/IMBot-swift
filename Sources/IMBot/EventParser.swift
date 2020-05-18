//
//  fetch_parse.swift
//  Testing bot
//
//  Created by v.metel on 02.03.2020.
//  Copyright © 2020 v.metel. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public struct Chat {
    public var chatId: String? = nil
    public var type:String? = nil
    public var title: String? = nil
}

public struct From {
    public var userId: String? = nil
    public var firstName:String? = nil
    public var lastName: String? = nil
    public var nick: String? = nil
}

public struct StickerParts {
    public var fileId: String? = nil
}

public struct MentionParts {
    public var userId: String? = nil
    public var firstName: String? = nil
    public var lastName: String? = nil
    public var nick: String? = nil
}

public struct VoiceParts {
    public var fileId: String? = nil
}

public struct FileParts {
    public var fileId: String? = nil
    public var type: String? = nil
    public var caption: String? = nil
}

public struct ForwardParts {
    public var message: NewMessage? = nil
}

public struct ReplyParts {
    public var message: NewMessage? = nil
}

public struct Parts {
    public var type: String? = nil
    public var part: Any
}

public struct NewMessage {
    public var text: String? = nil
    public var msgId: String? = nil
    public var timestamp: Int64? = nil
    public var chat: Chat?
    public var from: From?
    public var parts: Array<Parts>?
    public var fileId: String?
    public var editedTimestamp: Int64? = nil
}

public typealias LeftMembers = From
public typealias RemovedBy = From

public struct LeftChatMembers {
    public var chat: Chat?
    public var leftMembers: Array<LeftMembers>?
    public var removedBy: RemovedBy?
}

public typealias NewMembers = From
public typealias AddedBy = From

public struct NewChatMembers {
    public var chat: Chat?
    public var newMembers: Array<NewMembers>?
    public var addedBy: AddedBy?
}

public struct PinnedMessage {
    public var chat: Chat?
    public var from: From?
    public var text: String? = nil
    public var msgId: String? = nil
    public var timestamp: Int64? = nil
}

public struct UnpinnedMessage {
    public var chat: Chat?
    public var msgId: String? = nil
    public var timestamp: Int64? = nil
}

public struct DeletedMessage {
    public var chat: Chat?
    public var msgId: String? = nil
    public var timestamp: Int64? = nil
}

public struct EditedMessage {
    public var chat: Chat?
    public var from: From?
    public var msgId: String? = nil
    public var timestamp: Int64? = nil
    public var text: String? = nil
    public var editedTimestamp: Int64? = nil
}

public struct ChatInfo {
    public var titleChat: String?
    public var publicChat: Bool?
    public var joinModerationChat: Bool?
    public var inviteLinkChat: String?
    public var rulesChat: String?
    public var type: String?
    public var about: String?
    public var firstName: String?
    public var lastName: String?
    public var nick: String?
    public var isBot: Bool?
    public var userId: String?
    public var photo: Array<Photo>?
}

public struct Photo {
    public var url: String?
}

public struct Admin {
    public var userID: String?
    public var creator: Bool?
}

public struct Member {
    public var userID: String?
    public var creator: Bool?
    public var admin: Bool?
}

public struct User {
    public var userID: String?
}

public struct File {
    public var type: String?
    public var size: Int?
    public var filename: String?
    public var url: String?
}

public struct CallbackQuery {
    public var queryId: String?
    public var chat: Chat?
    public var from: From?
    public var message: NewMessage?
    public var callbackData: String?
}

public struct InlineKeyboardMarkup {
    public var buttons: Array<Array<Bot.BotButton>>?
}

func chatParse(_ json: JSON) -> Chat {
    var chat = Chat()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "chatId": chat.chatId = subJson.string
        case "type": chat.type = subJson.string
        case "title": chat.title = subJson.string
        default: assert(false, "Parse error in \"chat\"")
        }
    }
    return chat
}

func fromParse(_ json: JSON) -> From {
    var from = From()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "userId": from.userId = subJson.string
        case "firstName": from.firstName = subJson.string
        case "lastName": from.lastName = subJson.string
        case "nick": from.nick = subJson.string
        default: assert(false, "Parse error in \"from\"")
        }
    }
    return from
}

func stickerPartsParse(_ json: JSON) -> StickerParts {
    var stickerParts = StickerParts()
    stickerParts.fileId = json["fileId"].stringValue
    return stickerParts
}

func mentionPartsParse(_ json: JSON) -> MentionParts {
    var mentionParts = MentionParts()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "userId": mentionParts.userId = subJson.string
        case "firstName": mentionParts.firstName = subJson.string
        case "lastName": mentionParts.lastName = subJson.string
        case "nick": mentionParts.nick = subJson.string
        default: assert(false, "Parse error in \"mentionParts\"")
        }
    }
    return mentionParts
}

func voicePartsParse(_ json: JSON) -> VoiceParts {
    var voiceParts = VoiceParts()
    voiceParts.fileId = json["fileId"].stringValue
    return voiceParts
}

func filePartsParse(_ json: JSON) -> FileParts {
    var fileParts = FileParts()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "fileId": fileParts.fileId = subJson.string
        case "type": fileParts.type = subJson.string
        case "caption": fileParts.caption = subJson.string
        default: assert(false, "Parse error in \"fileParts\"")
        }
    }
    return fileParts
}

func forwardPartsParse(_ json: JSON) -> ForwardParts {
    var forwardParts = ForwardParts()
    forwardParts.message = messageParse(json["message"])
    return forwardParts
}

func replyPartsParse(_ json: JSON) -> ReplyParts {
    var replyParts = ReplyParts()
    replyParts.message = messageParse(json["message"])
    return replyParts
}

func inlineKeyboardMarkupParse(_ json: JSON) -> InlineKeyboardMarkup {
    var buttons = Array<Array<Bot.BotButton>>()
    for element in json.arrayValue {
        var buttonRow = Array<Bot.BotButton>()
        for subelement in element.arrayValue {
            var button = Bot.BotButton(text: "", url: nil)
            for (key,subJson):(String, JSON) in subelement {
                switch key {
                case "text": button.text = subJson.string!
                case "url": button.url = subJson.string
                case "callbackData": button.callbackData = subJson.string
                default: assert(false, "Parse error in \"inlineKeyboardMarkupParse\"")
                }
            }
            buttonRow.append(button)
        }
        buttons.append(buttonRow)
    }
    return InlineKeyboardMarkup(buttons: buttons)
}


func partsParse(_ json: JSON) -> [Parts] {
    var parts = Array<Parts>()
    for (_,subJson):(String, JSON) in json {
        switch subJson["type"].stringValue {
        case "sticker": parts.append(Parts(type: "sticker", part: stickerPartsParse(subJson["payload"])))
        case "mention": parts.append(Parts(type: "mention", part: mentionPartsParse(subJson["payload"])))
        case "voice": parts.append(Parts(type: "voice", part: voicePartsParse(subJson["payload"])))
        case "file": parts.append(Parts(type: "file", part: filePartsParse(subJson["payload"])))
        case "forward": parts.append(Parts(type: "forward", part: forwardPartsParse(subJson["payload"])))
        case "reply": parts.append(Parts(type: "reply", part: replyPartsParse(subJson["payload"])))
        case "inlineKeyboardMarkup": parts.append(Parts(type: "inlineKeyboardMarkup", part: inlineKeyboardMarkupParse(subJson["payload"])))
        default: assert(false, "Parse error in \"parts\"")
        }
    }
    return parts
}

func messageParse(_ json: JSON) -> NewMessage {
    var newMessage = NewMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "from": newMessage.from = fromParse(subJson)
        case "text": newMessage.text = subJson.string
        case "timestamp": newMessage.timestamp = subJson.int64
        case "msgId": newMessage.msgId = subJson.string
        case "chat": newMessage.chat = chatParse(subJson)
        case "parts": newMessage.parts = partsParse(subJson)
        case "editedTimestamp": newMessage.editedTimestamp = subJson.int64
        default: assert(false, "Parse error in \"message\"")
        }
    }
    return newMessage
}

func leftMembersParse(_ json: JSON) -> [LeftMembers] {
    var leftMembers = Array<LeftMembers>()
    for (_,subJson):(String, JSON) in json {
        leftMembers.append(fromParse(subJson))
    }
    return leftMembers
}

func leftChatMembersParse(_ json: JSON) -> LeftChatMembers{
    var leftChatMembers = LeftChatMembers()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "leftMembers": leftChatMembers.leftMembers = leftMembersParse(subJson)
        case "removedBy": leftChatMembers.removedBy = fromParse(subJson)
        case "chat": leftChatMembers.chat = chatParse(subJson)
        default: assert(false, "Parse error in \"leftChatMembers\"")
        }
    }
    return leftChatMembers
}

func newChatMembersParse(_ json: JSON) -> NewChatMembers {
    var newChatMembers = NewChatMembers()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "newMembers": newChatMembers.newMembers = leftMembersParse(subJson)
        case "addedBy": newChatMembers.addedBy = fromParse(subJson)
        case "chat": newChatMembers.chat = chatParse(subJson)
        default: assert(false, "Parse error in \"newChatMembers\"")
        }
    }
    return newChatMembers
}

func pinnedMessageParse(_ json: JSON) -> PinnedMessage {
    var pinnedMessage = PinnedMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "from": pinnedMessage.from = fromParse(subJson)
        case "text": pinnedMessage.text = subJson.string
        case "timestamp": pinnedMessage.timestamp = subJson.int64Value
        case "msgId": pinnedMessage.msgId = subJson.string
        case "chat": pinnedMessage.chat = chatParse(subJson)
        default: assert(false, "Parse error in \"pinnedMessage\"")
        }
    }
    return pinnedMessage
}

func unpinnedMessageParse(_ json: JSON) -> UnpinnedMessage {
    var unpinnedMessage = UnpinnedMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "timestamp": unpinnedMessage.timestamp = subJson.int64Value
        case "msgId": unpinnedMessage.msgId = subJson.string
        case "chat": unpinnedMessage.chat = chatParse(subJson)
        default: assert(false, "Parse error in \"unpinnedMessage\"")
        }
    }
    return unpinnedMessage
}

func deletedMessageParse(_ json: JSON) -> DeletedMessage {
    var deletedMessage = DeletedMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "timestamp": deletedMessage.timestamp = subJson.int64Value
        case "msgId": deletedMessage.msgId = subJson.string
        case "chat": deletedMessage.chat = chatParse(subJson)
        default: assert(false, "Parse error in \"deletedMessage\"")
        }
    }
    return deletedMessage
}

func editedMessageParse(_ json: JSON) -> EditedMessage {
    var editedMessage = EditedMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "timestamp": editedMessage.timestamp = subJson.int64Value
        case "msgId": editedMessage.msgId = subJson.string
        case "chat": editedMessage.chat = chatParse(subJson)
        case "from": editedMessage.from = fromParse(subJson)
        case "text": editedMessage.text = subJson.string
        case "editedTimestamp": editedMessage.editedTimestamp = subJson.int64Value
        default: assert(false, "Parse error in \"editedMessage\"")
        }
    }
    return editedMessage
}

func callbackQueryParse(_ json: JSON) -> CallbackQuery {
    var callbackQuery = CallbackQuery()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "callbackData": callbackQuery.callbackData = subJson.string
        case "chat": callbackQuery.chat = chatParse(subJson)
        case "from": callbackQuery.from = fromParse(subJson)
        case "message": callbackQuery.message = messageParse(subJson)
        case "queryId": callbackQuery.queryId = subJson.string
        default: assert(false, "Parse error in \"callbackQuery\"")
        }
    }
    return callbackQuery
}

func fetchParse(_ json: JSON) -> (Int64? ,Any?) {
    let eventId: Int64? = json["eventId"].int64
    var event: Any? = nil
    switch json["type"] {
    case "newMessage": event = messageParse(json["payload"])
    case "editedMessage": event = editedMessageParse(json["payload"])
    case "deletedMessage": event = deletedMessageParse(json["payload"])
    case "pinnedMessage": event = pinnedMessageParse(json["payload"])
    case "unpinnedMessage": event = unpinnedMessageParse(json["payload"])
    case "newChatMembers": event = newChatMembersParse(json["payload"])
    case "leftChatMembers": event = leftChatMembersParse(json["payload"])
    case "callbackQuery": event = callbackQueryParse(json["payload"])
    default: assert(false, "Parse error in \"fetch\"")
    }
    return (eventId, event)
}

func getInfoParse(_ json: JSON) -> ChatInfo {
    
    func photoParse(_ json:JSON) -> Array<Photo>? {
        var photosArray = Array<Photo>()
        for photos in json.arrayValue {
            for (key,subJson):(String, JSON) in photos {
                var photo = Photo()
                switch key {
                case "url": photo.url = subJson.string
                default: assert(false, "Parse error in \"parsePhoto\"")
                }
                photosArray.append(photo)
            }
        }
        return photosArray
    }
    
    var chatinfo = ChatInfo()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "title": chatinfo.titleChat = subJson.string
        case "public": chatinfo.publicChat = subJson.bool
        case "joinModeration": chatinfo.joinModerationChat = subJson.bool
        case "inviteLink": chatinfo.inviteLinkChat = subJson.string
        case "rules": chatinfo.rulesChat = subJson.string
        case "type": chatinfo.type = subJson.string
        case "about": chatinfo.about = subJson.string
        case "firstName": chatinfo.firstName = subJson.string
        case "lastName": chatinfo.lastName = subJson.string
        case "nick": chatinfo.nick = subJson.string
        case "isBot": chatinfo.isBot = subJson.bool
        case "userId": chatinfo.userId = subJson.string
        case "photo": chatinfo.photo = photoParse(subJson)
        case "ok": break
        case "description": break
        default: assert(false, "Parse error in \"chatInfo\"")
        }
    }
    return chatinfo
}

func getAdminsParse(_ json: JSON) -> Array<Admin> {
    
    func parseAdmins(_ json: JSON) -> Array<Admin> {
        var adminsArray = Array<Admin>()
        for admins in json.arrayValue {
            var admin = Admin()
            for (key,subJson):(String, JSON) in admins {
                switch key {
                case "userId": admin.userID = subJson.string
                case "creator": admin.creator = subJson.bool
                default: assert(false, "Parse error in \"parseAdmin\"")
                }
            }
            adminsArray.append(admin)
        }
        return adminsArray
    }
    
    var admins = Array<Admin>()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "admins": admins = (parseAdmins(subJson))
        case "ok": break
        case "description": break
        default: assert(false, "Parse error in \"getAdmins\"")
        }
    }
    return admins
}

func sendTextParse(_ json: JSON) -> NewMessage {
    var newMessage = NewMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "msgId": newMessage.msgId = subJson.string
        case "ok": break
        case "description": break
        default: assert(false, "Parse error in \"sendText\"")
        }
    }
    return newMessage
}

func sendFileParse(_ json: JSON) -> NewMessage {
    var newMessage = NewMessage()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "msgId": newMessage.msgId = subJson.string
        case "fileId": newMessage.fileId = subJson.string
        case "ok": break
        case "description": break
        default: assert(false, "Parse error in \"sendFile\"")
        }
    }
    return newMessage
}

func getMembersParse(_ json: JSON) -> Array<Member> {
    
    func parseMembers(_ json: JSON) -> Array<Member> {
        var membersArray = Array<Member>()
        for members in json.arrayValue {
            var member = Member()
            for (key,subJson):(String, JSON) in members {
                switch key {
                case "userId": member.userID = subJson.string
                case "creator": member.creator = subJson.bool
                case "admin": member.admin = subJson.bool
                default: assert(false, "Parse error in \"parseMember\"")
                }
            }
            membersArray.append(member)
        }
        return membersArray
    }
    
    var members = Array<Member>()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "members": members = (parseMembers(subJson))
        case "ok": break
        case "description": break
        default: assert(false, "Parse error in \"getMembers\"")
        }
    }
    return members
}

func getUsersParse(_ json: JSON) -> Array<User> {
    
    func parseMembers(_ json: JSON) -> Array<User> {
        var usersArray = Array<User>()
        for users in json.arrayValue {
            var user = User()
            for (key,subJson):(String, JSON) in users {
                switch key {
                case "userId": user.userID = subJson.string
                default: assert(false, "Parse error in \"parseMember\"")
                }
            }
            usersArray.append(user)
        }
        return usersArray
    }
    
    var users = Array<User>()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "users": users = (parseMembers(subJson))
        case "ok": break
        case "description": break
        default: assert(false, "Parse error in \"getMembers\"")
        }
    }
    return users
}

func filesGetInfoParse(_ json: JSON) -> File {
    var file = File()
    for (key,subJson):(String, JSON) in json {
        switch key {
        case "type": file.type = subJson.string
        case "size": file.size = subJson.int
        case "filename": file.filename = subJson.string
        case "url": file.url = subJson.string
        case "ok" : break
        case "description": break
        default: assert(false, "Parse error in \"filesGetInfo\"")
        }
    }
    return file
}
