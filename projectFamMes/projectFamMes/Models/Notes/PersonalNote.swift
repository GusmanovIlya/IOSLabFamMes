import Foundation

public struct PersonalNote: Identifiable, Codable, Hashable, Sendable {
    public let id: EntityID
    public var title: String?
    public var content: String
    public var updatedAt: Date

    public init(
        id: EntityID,
        title: String? = nil,
        content: String,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
    }
}
