import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    private let repo: ChatRepository
    private let roomId: EntityID
    private let currentUserId: EntityID

    var messages: [Message] = []
    var draft = ""
    var errorMessage: String?

    init(
        roomId: EntityID,
        currentUserId: EntityID = "me",
        repo: ChatRepository
    ) {
        self.roomId = roomId
        self.currentUserId = currentUserId
        self.repo = repo
    }

    func load() async {
        do {
            messages = try await repo.fetchMessages(roomId: roomId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            let newMessage = try await repo.sendMessage(
                roomId: roomId,
                senderId: currentUserId,
                text: text
            )

            messages.append(newMessage)
            draft = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isOutgoing(_ message: Message) -> Bool {
        message.senderId == currentUserId
    }
}
