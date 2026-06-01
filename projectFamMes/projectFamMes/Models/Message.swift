import Foundation

public enum MessageKind: String, Codable, Sendable {
    case text
    case system
}

public enum MessageStatus: String, Codable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

public struct Message: Identifiable, Codable, Hashable, Sendable {
    public let id: EntityID
    public let roomId: EntityID
    public let senderId: EntityID
    public var kind: MessageKind
    public var text: String
    public let createdAt: Date
    public var editedAt: Date?
    public var status: MessageStatus

    public init(
        id: EntityID,
        roomId: EntityID,
        senderId: EntityID,
        kind: MessageKind = .text,
        text: String,
        createdAt: Date,
        editedAt: Date? = nil,
        status: MessageStatus = .sent
    ) {
        self.id = id
        self.roomId = roomId
        self.senderId = senderId
        self.kind = kind
        self.text = text
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.status = status
    }
}
