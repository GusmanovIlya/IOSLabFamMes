import Foundation
import Observation

@MainActor
@Observable
final class ChatsHomeViewModel {
    private let repo: any ChatRepository

    var chats: [Chat] = []
    var allUsers: [UserSummary] = []
    var searchText = ""
    var errorMessage: String?

    init(repo: any ChatRepository) {
        self.repo = repo
    }

    var hasSearchQuery: Bool {
        !normalized(searchText).isEmpty
    }

    var filteredChats: [Chat] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return chats }

        return chats.filter { chat in
            normalized(chat.name).contains(query) ||
            normalized(chat.username).contains(query) ||
            normalized(chat.lastMessage).contains(query)
        }
    }

    var filteredUsers: [UserSummary] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return [] }

        let existingUsernames = Set(chats.map { normalized($0.username) })

        return allUsers.filter { user in
            let userMatches =
                normalized(user.name).contains(query) ||
                normalized(user.username).contains(query)

            let alreadyInChats = existingUsernames.contains(normalized(user.username))

            return userMatches && !alreadyInChats
        }
    }

    func load() async {
        do {
            async let chatsTask = repo.fetchChats()
            async let usersTask = repo.fetchAllUsers()

            chats = try await chatsTask
            allUsers = try await usersTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func chatForFoundUser(_ user: UserSummary) -> Chat {
        Chat(
            id: roomId(for: user),
            avatar: avatarName(for: user),
            name: user.name,
            username: user.username,
            lastMessage: "Начните переписку",
            time: ""
        )
    }

    private func roomId(for user: UserSummary) -> EntityID {
        "room_" + normalized(user.username)
    }

    private func avatarName(for user: UserSummary) -> String {
        switch normalized(user.username) {
        case "gusmanovilya":
            return "avatar1"
        case "annasmirnova", "alexey":
            return "avatar2"
        case "maria":
            return "avatar3"
        default:
            return "avatar4"
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }
}
