import Foundation

actor MockChatRepository: ChatRepository {
    private let currentUsername: String
    private var chats: [Chat]
    private var allUsers: [UserSummary]
    private var messagesByRoomId: [EntityID: [Message]]

    private var normalizedUsername: String {
        Self.normalizeStatic(currentUsername)
    }

    private var chatsKey: String {
        "mock_chats_\(normalizedUsername)"
    }

    private var messagesKey: String {
        "mock_messages_\(normalizedUsername)"
    }

    private var hasInitializedKey: String {
        "mock_chats_initialized_\(normalizedUsername)"
    }

    init(currentUsername: String = "GusmanovIlya") {
        self.currentUsername = currentUsername
        self.allUsers = Self.makeUsers(currentUsername: currentUsername)

        let normalizedUsername = Self.normalizeStatic(currentUsername)
        let chatsKey = "mock_chats_\(normalizedUsername)"
        let messagesKey = "mock_messages_\(normalizedUsername)"
        let hasInitializedKey = "mock_chats_initialized_\(normalizedUsername)"

        let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)

        if hasInitialized {
            self.chats = Self.loadChats(key: chatsKey)
            self.messagesByRoomId = Self.loadMessages(key: messagesKey)
        } else {
            self.chats = Self.makeChats(currentUsername: currentUsername)
            self.messagesByRoomId = Self.makeMessages(currentUsername: currentUsername)

            Self.saveChats(self.chats, key: chatsKey)
            Self.saveMessages(self.messagesByRoomId, key: messagesKey)
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
        }
    }

    func fetchChats() async throws -> [Chat] {
        chats
    }

    func fetchMessages(roomId: EntityID) async throws -> [Message] {
        messagesByRoomId[roomId, default: []]
            .sorted { $0.createdAt < $1.createdAt }
    }

    func sendMessage(roomId: EntityID, senderId: EntityID, text: String) async throws -> Message {
        try await appendMessage(
            roomId: roomId,
            senderId: senderId,
            text: text,
            status: .sent
        )
    }

    func receiveMessage(roomId: EntityID, senderId: EntityID, text: String) async throws -> Message {
        try await appendMessage(
            roomId: roomId,
            senderId: senderId,
            text: text,
            status: .delivered
        )
    }

    private func appendMessage(
        roomId: EntityID,
        senderId: EntityID,
        text: String,
        status: MessageStatus
    ) async throws -> Message {
        ensureChatExists(roomId: roomId)

        let now = Date.now

        let message = Message(
            id: UUID().uuidString,
            roomId: roomId,
            senderId: senderId,
            text: text,
            createdAt: now,
            status: status
        )

        messagesByRoomId[roomId, default: []].append(message)
        updateLastMessage(roomId: roomId, text: text, date: now)

        saveMessages()
        saveChats()

        NotificationCenter.default.post(
            name: .chatsDidChange,
            object: currentUsername
        )

        return message
    }

    private func ensureChatExists(roomId: EntityID) {
        guard !chats.contains(where: { $0.id == roomId }) else { return }
        guard let user = userForRoomId(roomId) else { return }

        let newChat = Chat(
            id: roomId,
            avatar: avatarName(for: user),
            name: user.name,
            username: user.username,
            lastMessage: "",
            time: ""
        )

        chats.insert(newChat, at: 0)
        saveChats()

        NotificationCenter.default.post(
            name: .chatsDidChange,
            object: currentUsername
        )
    }

    private func updateLastMessage(roomId: EntityID, text: String, date: Date) {
        guard let index = chats.firstIndex(where: { $0.id == roomId }) else { return }

        chats[index].lastMessage = text
        chats[index].time = Self.timeFormatter.string(from: date)

        let updatedChat = chats.remove(at: index)
        chats.insert(updatedChat, at: 0)
    }

    private func userForRoomId(_ roomId: EntityID) -> UserSummary? {
        let valueFromRoomId = roomId
            .replacingOccurrences(of: "room_", with: "")

        return allUsers.first { user in
            normalize(user.username) == normalize(valueFromRoomId) ||
            normalize(user.id.replacingOccurrences(of: "user_", with: "")) == normalize(valueFromRoomId)
        }
    }

    func fetchAllUsers() async throws -> [UserSummary] {
        allUsers
    }

    func searchAllUsers(byUsername query: String) async throws -> [UserSummary] {
        let trimmed = normalize(query)
        guard !trimmed.isEmpty else { return allUsers }

        return allUsers.filter {
            normalize($0.name).contains(trimmed) ||
            normalize($0.username).contains(trimmed)
        }
    }

    func fetchKnownUsers() async throws -> [UserSummary] {
        let usernamesInChats = Set(chats.map { normalize($0.username) })

        return allUsers.filter {
            usernamesInChats.contains(normalize($0.username))
        }
    }

    private func saveChats() {
        Self.saveChats(chats, key: chatsKey)
    }

    private func saveMessages() {
        Self.saveMessages(messagesByRoomId, key: messagesKey)
    }

    private func avatarName(for user: UserSummary) -> String {
        switch normalize(user.username) {
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

    private func normalize(_ text: String) -> String {
        Self.normalizeStatic(text)
    }
}

private extension MockChatRepository {
    static func makeUsers(currentUsername: String) -> [UserSummary] {
        let users = [
            UserSummary(id: "user_gusmanov_ilya", name: "Илья Гусманов", username: "GusmanovIlya"),
            UserSummary(id: "user_anna_smirnova", name: "Анна Смирнова", username: "AnnaSmirnova"),
            UserSummary(id: "user_alexey", name: "Алексей", username: "alexey"),
            UserSummary(id: "user_maria", name: "Мария", username: "maria"),
            UserSummary(id: "user_kirill", name: "Кирилл", username: "kirill"),
            UserSummary(id: "user_arina", name: "Арина", username: "arina")
        ]

        return users.filter {
            normalizeStatic($0.username) != normalizeStatic(currentUsername)
        }
    }

    static func makeChats(currentUsername: String) -> [Chat] {
        switch normalizeStatic(currentUsername) {
        case "gusmanovilya":
            return [
                Chat(
                    id: "room_annasmirnova",
                    avatar: "avatar2",
                    name: "Анна Смирнова",
                    username: "AnnaSmirnova",
                    lastMessage: "Сделай, пожалуйста, регистрацию аккуратнее",
                    time: "12:45"
                ),
                Chat(
                    id: "room_alexey",
                    avatar: "avatar2",
                    name: "Алексей",
                    username: "alexey",
                    lastMessage: "Создать бд для хранения",
                    time: "11:20"
                ),
                Chat(
                    id: "room_maria",
                    avatar: "avatar3",
                    name: "Мария",
                    username: "maria",
                    lastMessage: "Добавить общие заметки, пока можно только парные",
                    time: "10:05"
                )
            ]

        case "annasmirnova":
            return [
                Chat(
                    id: "room_gusmanovilya",
                    avatar: "avatar1",
                    name: "Илья Гусманов",
                    username: "GusmanovIlya",
                    lastMessage: "Я добавил мок-аккаунты для теста",
                    time: "13:10"
                ),
                Chat(
                    id: "room_maria",
                    avatar: "avatar3",
                    name: "Мария",
                    username: "maria",
                    lastMessage: "Посмотрю дизайн формы входа",
                    time: "10:05"
                )
            ]

        default:
            return []
        }
    }

    static func makeMessages(currentUsername: String) -> [EntityID: [Message]] {
        switch normalizeStatic(currentUsername) {
        case "gusmanovilya":
            return [
                "room_annasmirnova": [
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_annasmirnova",
                        senderId: "Анна",
                        text: "Привет! Давай сделаем нормальный экран входа?",
                        createdAt: .now.addingTimeInterval(-7600),
                        status: .read
                    ),
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_annasmirnova",
                        senderId: "me",
                        text: "Да, добавлю регистрацию и два мок-аккаунта.",
                        createdAt: .now.addingTimeInterval(-7200),
                        status: .read
                    ),
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_annasmirnova",
                        senderId: "Анна",
                        text: "Сделай, пожалуйста, регистрацию аккуратнее",
                        createdAt: .now.addingTimeInterval(-1800),
                        status: .delivered
                    )
                ],
                "room_alexey": [
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_alexey",
                        senderId: "Алексей",
                        text: "Скинь, пожалуйста, код проекта",
                        createdAt: .now.addingTimeInterval(-3600),
                        status: .delivered
                    )
                ],
                "room_maria": [
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_maria",
                        senderId: "Мария",
                        text: "Сегодня созвон в 18:00",
                        createdAt: .now.addingTimeInterval(-5400),
                        status: .read
                    )
                ]
            ]

        case "annasmirnova":
            return [
                "room_gusmanovilya": [
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_gusmanovilya",
                        senderId: "Илья",
                        text: "Привет! Я сделал вход и регистрацию через мок-данные.",
                        createdAt: .now.addingTimeInterval(-7600),
                        status: .read
                    ),
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_gusmanovilya",
                        senderId: "me",
                        text: "Отлично, проверю второй аккаунт.",
                        createdAt: .now.addingTimeInterval(-7200),
                        status: .read
                    ),
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_gusmanovilya",
                        senderId: "Илья",
                        text: "Я добавил мок-аккаунты для теста",
                        createdAt: .now.addingTimeInterval(-1800),
                        status: .delivered
                    )
                ],
                "room_maria": [
                    Message(
                        id: UUID().uuidString,
                        roomId: "room_maria",
                        senderId: "Мария",
                        text: "Посмотрю дизайн формы входа",
                        createdAt: .now.addingTimeInterval(-5400),
                        status: .read
                    )
                ]
            ]

        default:
            return [:]
        }
    }

    static func loadChats(key: String) -> [Chat] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let chats = try? JSONDecoder().decode([Chat].self, from: data) else {
            return []
        }

        return chats
    }

    static func saveChats(_ chats: [Chat], key: String) {
        guard let data = try? JSONEncoder().encode(chats) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func loadMessages(key: String) -> [EntityID: [Message]] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let messages = try? JSONDecoder().decode([EntityID: [Message]].self, from: data) else {
            return [:]
        }

        return messages
    }

    static func saveMessages(_ messages: [EntityID: [Message]], key: String) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func normalizeStatic(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
