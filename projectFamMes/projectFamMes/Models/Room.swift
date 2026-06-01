import Foundation

public struct Room: Identifiable, Codable, Hashable, Sendable {
    public let id: EntityID
    public var kind: RoomKind
    public var title: String?
    public var memberIds: [EntityID]
    public var lastActivityAt: Date
    public var lastPreview: String?

    public init(
        id: EntityID,
        kind: RoomKind,
        title: String? = nil,
        memberIds: [EntityID],
        lastActivityAt: Date,
        lastPreview: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.memberIds = memberIds
        self.lastActivityAt = lastActivityAt
        self.lastPreview = lastPreview
    }
}
