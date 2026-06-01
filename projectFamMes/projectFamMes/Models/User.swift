import Foundation

public struct User: Identifiable, Codable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var username: String
    public var password: String
    public var avatarName: String
    public var bio: String
    public var avatarURL: URL?
    public var friendIds: [EntityID]

    public init(
        id: EntityID = UUID().uuidString,
        name: String,
        username: String,
        password: String,
        avatarName: String = "avatar4",
        bio: String = "Участник FamMes",
        avatarURL: URL? = nil,
        friendIds: [EntityID] = []
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.avatarName = avatarName
        self.bio = bio
        self.avatarURL = avatarURL
        self.friendIds = friendIds
    }
}

public struct UserSummary: Identifiable, Codable, Hashable, Sendable {
    public let id: EntityID
    public var name: String
    public var username: String
    public var avatarName: String = "avatar4"
    public var avatarURL: URL?

    public init(id: EntityID, name: String, username: String, avatarName: String = "avatar4", avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.avatarName = avatarName
        self.avatarURL = avatarURL
    }
}
