import Foundation

actor MockNotesRepository: NotesRepository {
    private let username: String
    
    private var personal: [PersonalNote] = []
    private var shared: [SharedNote] = []
    
    private var personalKey: String {
        "personal_notes_\(normalizedUsername)"
    }
    
    private var sharedKey: String {
        "shared_notes_\(normalizedUsername)"
    }

    private var normalizedUsername: String {
        username
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "@", with: "")
    }
    
    init(username: String) {
        self.username = username

        let hasInitializedKey = "notes_initialized_\(normalizedUsername)"
        let hasInitializedSharedKey = "shared_notes_initialized_\(normalizedUsername)"

        let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)
        let hasInitializedShared = UserDefaults.standard.bool(forKey: hasInitializedSharedKey)

        if hasInitialized {
            self.personal = Self.loadPersonalNotes(key: personalKey)
        } else {
            self.personal = Self.makeMockPersonalNotes(username: normalizedUsername)
            savePersonalNotes()
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
        }

        if hasInitializedShared {
            self.shared = Self.loadSharedNotes(key: sharedKey)
        } else {
            self.shared = Self.makeGlobalMockSharedNotes()
            saveSharedNotes()
            UserDefaults.standard.set(true, forKey: hasInitializedSharedKey)
        }
    }

    func fetchPersonalNotes() async throws -> [PersonalNote] {
        personal.sorted { $0.updatedAt > $1.updatedAt }
    }

    func createPersonalNote(title: String?, content: String) async throws -> PersonalNote {
        let note = PersonalNote(
            id: UUID().uuidString,
            title: title,
            content: content,
            updatedAt: .now
        )
        
        personal.insert(note, at: 0)
        savePersonalNotes()
        
        return note
    }

    func updatePersonalNote(id: EntityID, title: String?, content: String) async throws -> PersonalNote {
        guard let index = personal.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "MockNotesRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Заметка не найдена"
            ])
        }

        personal[index].title = title
        personal[index].content = content
        personal[index].updatedAt = .now
        
        savePersonalNotes()

        return personal[index]
    }

    func deletePersonalNote(id: EntityID) async throws {
        guard let index = personal.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "MockNotesRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Заметка не найдена"
            ])
        }

        personal.remove(at: index)
        savePersonalNotes()
    }
    
    func fetchSharedNotes() async throws -> [SharedNote] {
        shared.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func createSharedNote(
        roomId: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async throws -> SharedNote {
        let note = SharedNote(
            id: UUID().uuidString,
            roomId: roomId,
            title: title,
            content: content,
            members: members,
            updatedAt: .now
        )
        
        shared.insert(note, at: 0)
        saveSharedNotes()
        
        return note
    }
    
    func updateSharedNote(
        id: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async throws -> SharedNote {
        guard let index = shared.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "MockNotesRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Общая заметка не найдена"
            ])
        }

        shared[index].title = title
        shared[index].content = content
        shared[index].members = members
        shared[index].updatedAt = .now
        
        saveSharedNotes()
        
        return shared[index]
    }
    
    func deleteSharedNote(id: EntityID) async throws {
        guard let index = shared.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "MockNotesRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Общая заметка не найдена"
            ])
        }
        
        shared.remove(at: index)
        saveSharedNotes()
    }
    
    private func savePersonalNotes() {
        guard let data = try? JSONEncoder().encode(personal) else { return }
        UserDefaults.standard.set(data, forKey: personalKey)
    }
    
    private func saveSharedNotes() {
        guard let data = try? JSONEncoder().encode(shared) else { return }
        UserDefaults.standard.set(data, forKey: sharedKey)
    }

    private static func makeMockPersonalNotes(username: String) -> [PersonalNote] {
        switch username.lowercased() {
        case "annasmirnova":
            return [
                PersonalNote(
                    id: "anna_personal_1",
                    title: "Идеи для дизайна",
                    content: "Сделать экран входа чище: крупный заголовок, карточки демо-аккаунтов, понятные ошибки.",
                    updatedAt: .now.addingTimeInterval(-3600)
                ),
                PersonalNote(
                    id: "anna_personal_2",
                    title: "Проверить регистрацию",
                    content: "Проверить пустые поля, короткий пароль, повтор пароля и занятый логин.",
                    updatedAt: .now.addingTimeInterval(-9000)
                )
            ]

        case "gusmanovilya":
            return [
                PersonalNote(
                    id: "ilya_personal_1",
                    title: "План по авторизации",
                    content: "1. Два мок-аккаунта. 2. Регистрация нового пользователя. 3. Отдельные заметки для каждого аккаунта.",
                    updatedAt: .now.addingTimeInterval(-2400)
                ),
                PersonalNote(
                    id: "ilya_personal_2",
                    title: "Что протестировать",
                    content: "Войти под Ильёй, выйти, войти под Анной, создать новый аккаунт и проверить профиль.",
                    updatedAt: .now.addingTimeInterval(-7200)
                )
            ]

        default:
            return []
        }
    }

    private static func makeGlobalMockSharedNotes() -> [SharedNote] {
        [
            SharedNote(
                id: "shared_note_global_1",
                roomId: "global_room",
                title: "Общая заметка для всех",
                content: "Эту заметку видят все пользователи. Любой пользователь может открыть её и изменить.",
                members: [
                    NoteMember(id: "user_1", name: "Все пользователи")
                ],
                updatedAt: .now.addingTimeInterval(-1200)
            )
        ]
    }

    private static func loadPersonalNotes(key: String) -> [PersonalNote] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let notes = try? JSONDecoder().decode([PersonalNote].self, from: data) else {
            return []
        }
        
        return notes
    }
    
    private static func loadSharedNotes(key: String) -> [SharedNote] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let notes = try? JSONDecoder().decode([SharedNote].self, from: data) else {
            return []
        }
        
        return notes
    }
}
