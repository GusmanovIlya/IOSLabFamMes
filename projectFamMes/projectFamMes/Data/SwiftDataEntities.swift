import Foundation
import SwiftData

@Model
final class UserEntity {
    @Attribute(.unique) var id: String
    var name: String
    var username: String
    var password: String
    var avatarName: String
    var bio: String
    var avatarURLString: String?
    var friendIdsData: Data

    init(
        id: String = UUID().uuidString,
        name: String,
        username: String,
        password: String,
        avatarName: String = "avatar4",
        bio: String = "Участник FamMes",
        avatarURLString: String? = nil,
        friendIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.avatarName = avatarName
        self.bio = bio
        self.avatarURLString = avatarURLString
        self.friendIdsData = (try? JSONEncoder().encode(friendIds)) ?? Data()
    }

    var friendIds: [String] {
        (try? JSONDecoder().decode([String].self, from: friendIdsData)) ?? []
    }

    var model: User {
        User(
            id: id,
            name: name,
            username: username,
            password: password,
            avatarName: avatarName,
            bio: bio,
            avatarURL: avatarURLString.flatMap(URL.init(string:)),
            friendIds: friendIds
        )
    }

    var summary: UserSummary {
        UserSummary(
            id: id,
            name: name,
            username: username,
            avatarName: avatarName,
            avatarURL: avatarURLString.flatMap(URL.init(string:))
        )
    }
}

@Model
final class ChatEntity {
    @Attribute(.unique) var storageId: String

    var id: String
    var ownerUsername: String
    var avatar: String
    var name: String
    var username: String
    var lastMessage: String
    var time: String
    var updatedAt: Date

    init(
        id: String,
        ownerUsername: String,
        avatar: String,
        name: String,
        username: String,
        lastMessage: String,
        time: String,
        updatedAt: Date = .now
    ) {
        self.storageId = "\(ownerUsername.lowercased())_\(id)"
        self.id = id
        self.ownerUsername = ownerUsername
        self.avatar = avatar
        self.name = name
        self.username = username
        self.lastMessage = lastMessage
        self.time = time
        self.updatedAt = updatedAt
    }

    var model: Chat {
        Chat(
            id: id,
            avatar: avatar,
            name: name,
            username: username,
            lastMessage: lastMessage,
            time: time
        )
    }
}

@Model
final class MessageEntity {
    @Attribute(.unique) var id: String

    var ownerUsername: String
    var roomId: String
    var senderId: String
    var kindRawValue: String
    var text: String
    var createdAt: Date
    var editedAt: Date?
    var statusRawValue: String

    init(
        id: String = UUID().uuidString,
        ownerUsername: String,
        roomId: String,
        senderId: String,
        kind: MessageKind = .text,
        text: String,
        createdAt: Date = .now,
        editedAt: Date? = nil,
        status: MessageStatus = .sent
    ) {
        self.id = id
        self.ownerUsername = ownerUsername
        self.roomId = roomId
        self.senderId = senderId
        self.kindRawValue = kind.rawValue
        self.text = text
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.statusRawValue = status.rawValue
    }

    var model: Message {
        Message(
            id: id,
            roomId: roomId,
            senderId: senderId,
            kind: MessageKind(rawValue: kindRawValue) ?? .text,
            text: text,
            createdAt: createdAt,
            editedAt: editedAt,
            status: MessageStatus(rawValue: statusRawValue) ?? .sent
        )
    }
}

@Model
final class PersonalNoteEntity {
    @Attribute(.unique) var id: String

    var ownerUsername: String
    var title: String?
    var content: String
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        ownerUsername: String,
        title: String?,
        content: String,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerUsername = ownerUsername
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
    }

    var model: PersonalNote {
        PersonalNote(
            id: id,
            title: title,
            content: content,
            updatedAt: updatedAt
        )
    }
}

@Model
final class SharedNoteEntity {
    @Attribute(.unique) var id: String

    var ownerUsername: String
    var roomId: String
    var title: String?
    var content: String
    var membersData: Data
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        ownerUsername: String,
        roomId: String,
        title: String?,
        content: String,
        members: [NoteMember],
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerUsername = ownerUsername
        self.roomId = roomId
        self.title = title
        self.content = content
        self.membersData = (try? JSONEncoder().encode(members)) ?? Data()
        self.updatedAt = updatedAt
    }

    var members: [NoteMember] {
        (try? JSONDecoder().decode([NoteMember].self, from: membersData)) ?? []
    }

    func setMembers(_ members: [NoteMember]) {
        membersData = (try? JSONEncoder().encode(members)) ?? Data()
    }

    var model: SharedNote {
        SharedNote(
            id: id,
            roomId: roomId,
            title: title,
            content: content,
            members: members,
            updatedAt: updatedAt
        )
    }
}

@Model
final class AppSessionEntity {
    @Attribute(.unique) var id: String
    var userId: String
    var username: String

    init(
        id: String = "current",
        userId: String,
        username: String
    ) {
        self.id = id
        self.userId = userId
        self.username = username
    }
}
