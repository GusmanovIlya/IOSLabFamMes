import Foundation
import SwiftData

@MainActor
final class SwiftDataChatRepository: ChatRepository {
    private let modelContext: ModelContext
    private let currentUsername: String

    private var normalizedUsername: String {
        Self.normalize(currentUsername)
    }

    init(modelContext: ModelContext, currentUsername: String) {
        self.modelContext = modelContext
        self.currentUsername = currentUsername

        seedChatsIfNeeded()
    }

    func fetchChats() async throws -> [Chat] {
        let owner = normalizedUsername

        let descriptor = FetchDescriptor<ChatEntity>(
            predicate: #Predicate {
                $0.ownerUsername == owner
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).map(\.model)
    }

    func fetchMessages(roomId: EntityID) async throws -> [Message] {
        let owner = normalizedUsername

        let descriptor = FetchDescriptor<MessageEntity>(
            predicate: #Predicate {
                $0.ownerUsername == owner && $0.roomId == roomId
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        return try modelContext.fetch(descriptor).map(\.model)
    }

    func sendMessage(roomId: EntityID, senderId: EntityID, text: String) async throws -> Message {
        try appendMessage(
            roomId: roomId,
            senderId: senderId,
            text: text,
            status: .sent
        )
    }

    func receiveMessage(roomId: EntityID, senderId: EntityID, text: String) async throws -> Message {
        try appendMessage(
            roomId: roomId,
            senderId: senderId,
            text: text,
            status: .delivered
        )
    }

    func fetchAllUsers() async throws -> [UserSummary] {
        let descriptor = FetchDescriptor<UserEntity>(
            sortBy: [SortDescriptor(\.name)]
        )

        return try modelContext.fetch(descriptor)
            .map(\.summary)
            .filter {
                Self.normalize($0.username) != normalizedUsername
            }
    }

    func searchAllUsers(byUsername query: String) async throws -> [UserSummary] {
        let query = Self.normalize(query)

        let users = try await fetchAllUsers()

        guard !query.isEmpty else {
            return users
        }

        return users.filter {
            Self.normalize($0.name).contains(query) ||
            Self.normalize($0.username).contains(query)
        }
    }

    func fetchKnownUsers() async throws -> [UserSummary] {
        let chats = try await fetchChats()
        let usernames = Set(chats.map { Self.normalize($0.username) })

        return try await fetchAllUsers().filter {
            usernames.contains(Self.normalize($0.username))
        }
    }

    private func appendMessage(
        roomId: EntityID,
        senderId: EntityID,
        text: String,
        status: MessageStatus
    ) throws -> Message {
        try ensureChatExists(roomId: roomId)

        let now = Date.now

        let messageEntity = MessageEntity(
            ownerUsername: normalizedUsername,
            roomId: roomId,
            senderId: senderId,
            text: text,
            createdAt: now,
            status: status
        )

        modelContext.insert(messageEntity)

        if let chat = try fetchChatEntity(roomId: roomId) {
            chat.lastMessage = text
            chat.time = Self.timeFormatter.string(from: now)
            chat.updatedAt = now
        }

        try modelContext.save()

        NotificationCenter.default.post(
            name: .chatsDidChange,
            object: currentUsername
        )

        return messageEntity.model
    }

    private func ensureChatExists(roomId: EntityID) throws {
        if try fetchChatEntity(roomId: roomId) != nil {
            return
        }

        let usernameFromRoom = roomId.replacingOccurrences(of: "room_", with: "")

        let usersDescriptor = FetchDescriptor<UserEntity>()
        let users = try modelContext.fetch(usersDescriptor)

        let user = users.first {
            Self.normalize($0.username) == Self.normalize(usernameFromRoom) ||
            Self.normalize($0.id.replacingOccurrences(of: "user_", with: "")) == Self.normalize(usernameFromRoom)
        }

        let chat = ChatEntity(
            id: roomId,
            ownerUsername: normalizedUsername,
            avatar: user?.avatarName ?? "avatar4",
            name: user?.name ?? usernameFromRoom,
            username: user?.username ?? usernameFromRoom,
            lastMessage: "",
            time: "",
            updatedAt: .now
        )

        modelContext.insert(chat)
        try modelContext.save()
    }

    private func fetchChatEntity(roomId: EntityID) throws -> ChatEntity? {
        let owner = normalizedUsername

        let descriptor = FetchDescriptor<ChatEntity>(
            predicate: #Predicate {
                $0.ownerUsername == owner && $0.id == roomId
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    private func seedChatsIfNeeded() {
        let owner = normalizedUsername

        let descriptor = FetchDescriptor<ChatEntity>(
            predicate: #Predicate {
                $0.ownerUsername == owner
            }
        )

        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else {
            return
        }

        switch owner {
        case "gusmanovilya":
            insertChat(
                id: "room_annasmirnova",
                avatar: "avatar2",
                name: "Анна Смирнова",
                username: "AnnaSmirnova",
                lastMessage: "Сделай, пожалуйста, регистрацию аккуратнее",
                time: "12:45",
                updatedAt: .now.addingTimeInterval(-1800)
            )

            insertChat(
                id: "room_alexey",
                avatar: "avatar2",
                name: "Алексей",
                username: "alexey",
                lastMessage: "Создать бд для хранения",
                time: "11:20",
                updatedAt: .now.addingTimeInterval(-3600)
            )

            insertChat(
                id: "room_maria",
                avatar: "avatar3",
                name: "Мария",
                username: "maria",
                lastMessage: "Добавить общие заметки",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )

            insertMessage(
                roomId: "room_annasmirnova",
                senderId: "Анна",
                text: "Привет! Давай сделаем нормальный экран входа?",
                createdAt: .now.addingTimeInterval(-7600),
                status: .read
            )

            insertMessage(
                roomId: "room_annasmirnova",
                senderId: "me",
                text: "Да, добавлю регистрацию и два аккаунта.",
                createdAt: .now.addingTimeInterval(-7200),
                status: .read
            )

            insertMessage(
                roomId: "room_annasmirnova",
                senderId: "Анна",
                text: "Сделай, пожалуйста, регистрацию аккуратнее",
                createdAt: .now.addingTimeInterval(-1800),
                status: .delivered
            )

        case "annasmirnova":
            insertChat(
                id: "room_gusmanovilya",
                avatar: "avatar1",
                name: "Илья Гусманов",
                username: "GusmanovIlya",
                lastMessage: "Я добавил мок-аккаунты для теста",
                time: "13:10",
                updatedAt: .now.addingTimeInterval(-1800)
            )

            insertChat(
                id: "room_maria",
                avatar: "avatar3",
                name: "Мария",
                username: "maria",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )
            
            insertChat(
                id: "room_killbill",
                avatar: "avatar7",
                name: "killbill",
                username: "killbill",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )
            
            insertChat(
                id: "room_Steven",
                avatar: "avatar6",
                name: "Steven",
                username: "Steven",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )
            
            insertChat(
                id: "room_kaiangel",
                avatar: "avatar6",
                name: "kaiangel",
                username: "kaiangel",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )
            
            
            
            insertChat(
                id: "room_9mice",
                avatar: "avatar8",
                name: "9mice",
                username: "9mice",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )
            
            insertChat(
                id: "room_pharaoh",
                avatar: "avatar9",
                name: "pharaoh",
                username: "pharaoh",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )
            
            insertChat(
                id: "room_trappa",
                avatar: "avatar10",
                name: "trappa",
                username: "trappa",
                lastMessage: "Посмотрю дизайн формы входа",
                time: "10:05",
                updatedAt: .now.addingTimeInterval(-5400)
            )

            insertMessage(
                roomId: "room_gusmanovilya",
                senderId: "Илья",
                text: "Привет! Я сделал вход и регистрацию.",
                createdAt: .now.addingTimeInterval(-7600),
                status: .read
            )

            insertMessage(
                roomId: "room_gusmanovilya",
                senderId: "me",
                text: "Отлично, проверю второй аккаунт.",
                createdAt: .now.addingTimeInterval(-7200),
                status: .read
            )

            insertMessage(
                roomId: "room_gusmanovilya",
                senderId: "Илья",
                text: "Я добавил мок-аккаунты для теста",
                createdAt: .now.addingTimeInterval(-1800),
                status: .delivered
            )

        default:
            break
        }

        try? modelContext.save()
    }

    private func insertChat(
        id: String,
        avatar: String,
        name: String,
        username: String,
        lastMessage: String,
        time: String,
        updatedAt: Date
    ) {
        modelContext.insert(
            ChatEntity(
                id: id,
                ownerUsername: normalizedUsername,
                avatar: avatar,
                name: name,
                username: username,
                lastMessage: lastMessage,
                time: time,
                updatedAt: updatedAt
            )
        )
    }

    private func insertMessage(
        roomId: String,
        senderId: String,
        text: String,
        createdAt: Date,
        status: MessageStatus
    ) {
        modelContext.insert(
            MessageEntity(
                ownerUsername: normalizedUsername,
                roomId: roomId,
                senderId: senderId,
                text: text,
                createdAt: createdAt,
                status: status
            )
        )
    }

    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
