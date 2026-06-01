import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AuthViewModel {
    var currentUser: User?

    private let modelContext: ModelContext
    private let sessionId = "current"

    private let mockUsers: [User] = [
        User(
            id: "user_gusmanov_ilya",
            name: "Илья Гусманов",
            username: "GusmanovIlya",
            password: "1234",
            avatarName: "avatar1",
            bio: "iOS / Swift Developer"
        ),
        User(
            id: "user_anna_smirnova",
            name: "Анна Смирнова",
            username: "AnnaSmirnova",
            password: "1234",
            avatarName: "avatar2",
            bio: "Product Designer"
        )
    ]

    private let extraUsers: [User] = [
            User(id: "user_arina", name: "Арина", username: "kaiangel", password: "1234", avatarName: "avatar6", bio: "Участник FamMes"),
            User(id: "user_roman", name: "Роман", username: "pharaoh", password: "1234", avatarName: "avatar9", bio: "Участник FamMes"),
            User(id: "user_sofia", name: "София", username: "9mice", password: "1234", avatarName: "avatar10", bio: "Участник FamMes"),
            User(id: "user_timur", name: "Тимур", username: "trappa", password: "1234", avatarName: "avatar7", bio: "Участник FamMes"),
            User(id: "user_lera", name: "Лера", username: "explorer", password: "1234", avatarName: "avatar8", bio: "Участник FamMes"),
            User(id: "user_as", name: "Лера", username: "face", password: "1234", avatarName: "avatar11", bio: "Участник FamMes"),
            User(id: "user_ds", name: "Лера", username: "heroin", password: "1234", avatarName: "avatar12", bio: "Участник FamMes"),
            User(id: "user_qw", name: "Лера", username: "based", password: "1234", avatarName: "avatar13", bio: "Участник FamMes"),
        User(
            id: "user_alexey",
            name: "Алексей",
            username: "alexey",
            password: "1234",
            avatarName: "avatar2",
            bio: "Участник FamMes"
        ),
        User(
            id: "user_maria",
            name: "Мария",
            username: "maria",
            password: "1234",
            avatarName: "avatar3",
            bio: "Участник FamMes"
        ),
        User(
            id: "user_kirill",
            name: "Кирилл",
            username: "kirill",
            password: "1234",
            avatarName: "avatar4",
            bio: "Участник FamMes"
        ),
        User(
            id: "user_arina",
            name: "Арина",
            username: "arina",
            password: "1234",
            avatarName: "avatar4",
            bio: "Участник FamMes"
        )
    ]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        seedUsersIfNeeded()
        loadCurrentUser()
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    var demoUsers: [User] {
        mockUsers
    }

    func login(username: String, password: String) -> Bool {
        let normalizedUsername = normalize(username)

        guard let user = fetchUsers().first(where: {
            normalize($0.username) == normalizedUsername && $0.password == password
        }) else {
            return false
        }

        currentUser = user
        saveSession(for: user)

        return true
    }

    func register(name: String, username: String, password: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedUsername = normalize(trimmedUsername)

        let usernameAlreadyExists = fetchUsers().contains {
            normalize($0.username) == normalizedUsername
        }

        guard !usernameAlreadyExists else {
            return false
        }

        let newUser = User(
            name: trimmedName.isEmpty ? trimmedUsername : trimmedName,
            username: trimmedUsername,
            password: password,
            avatarName: "avatar4",
            bio: "Новый участник FamMes"
        )

        let entity = UserEntity(
            id: newUser.id,
            name: newUser.name,
            username: newUser.username,
            password: newUser.password,
            avatarName: newUser.avatarName,
            bio: newUser.bio,
            avatarURLString: newUser.avatarURL?.absoluteString,
            friendIds: newUser.friendIds
        )

        modelContext.insert(entity)
        try? modelContext.save()

        currentUser = newUser
        saveSession(for: newUser)

        return true
    }

    func register(username: String, password: String) -> Bool {
        register(name: username, username: username, password: password)
    }

    func updateBio(_ bio: String) {
        guard var user = currentUser else { return }

        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        if let entity = fetchUserEntity(username: user.username) {
            entity.bio = user.bio
            try? modelContext.save()
        }

        currentUser = user
        saveSession(for: user)
    }

    func logout() {
        currentUser = nil

        if let session = fetchCurrentSession() {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }

    private func seedUsersIfNeeded() {
        let users = mockUsers + extraUsers

        for user in users {
            if let entity = fetchUserEntity(username: user.username) {
                entity.name = user.name
                entity.password = user.password
                entity.avatarName = user.avatarName
                entity.bio = user.bio
            } else {
                modelContext.insert(
                    UserEntity(
                        id: user.id,
                        name: user.name,
                        username: user.username,
                        password: user.password,
                        avatarName: user.avatarName,
                        bio: user.bio,
                        avatarURLString: user.avatarURL?.absoluteString,
                        friendIds: user.friendIds
                    )
                )
            }
        }

        try? modelContext.save()
    }

    private func fetchUsers() -> [User] {
        let descriptor = FetchDescriptor<UserEntity>(
            sortBy: [SortDescriptor(\.name)]
        )

        return ((try? modelContext.fetch(descriptor)) ?? []).map(\.model)
    }

    private func fetchUserEntity(username: String) -> UserEntity? {
        let normalizedUsername = normalize(username)

        let descriptor = FetchDescriptor<UserEntity>()

        return ((try? modelContext.fetch(descriptor)) ?? []).first {
            normalize($0.username) == normalizedUsername
        }
    }

    private func loadCurrentUser() {
        guard let session = fetchCurrentSession() else {
            currentUser = nil
            return
        }

        currentUser = fetchUsers().first {
            $0.id == session.userId || normalize($0.username) == normalize(session.username)
        }
    }

    private func saveSession(for user: User) {
        if let session = fetchCurrentSession() {
            session.userId = user.id
            session.username = user.username
        } else {
            modelContext.insert(
                AppSessionEntity(
                    id: sessionId,
                    userId: user.id,
                    username: user.username
                )
            )
        }

        try? modelContext.save()
    }

    private func fetchCurrentSession() -> AppSessionEntity? {
        let id = sessionId

        let descriptor = FetchDescriptor<AppSessionEntity>(
            predicate: #Predicate {
                $0.id == id
            }
        )

        return try? modelContext.fetch(descriptor).first
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }
}
