import Foundation

protocol ChatRepository {
    func fetchChats() async throws -> [Chat]
    func fetchMessages(roomId: EntityID) async throws -> [Message]

    func sendMessage(roomId: EntityID, senderId: EntityID, text: String) async throws -> Message
    func receiveMessage(roomId: EntityID, senderId: EntityID, text: String) async throws -> Message

    func fetchAllUsers() async throws -> [UserSummary]
    func searchAllUsers(byUsername query: String) async throws -> [UserSummary]

    func fetchKnownUsers() async throws -> [UserSummary]
}

extension Notification.Name {
    static let chatsDidChange = Notification.Name("chatsDidChange")
}
