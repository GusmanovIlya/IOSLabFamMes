import Foundation
import SwiftData

@MainActor
final class SwiftDataNotesRepository: NotesRepository {
    private let modelContext: ModelContext
    private let username: String

    init(modelContext: ModelContext, username: String) {
        self.modelContext = modelContext
        self.username = Self.normalize(username)
    }

    func fetchPersonalNotes() async throws -> [PersonalNote] {
        let owner = username

        let descriptor = FetchDescriptor<PersonalNoteEntity>(
            predicate: #Predicate {
                $0.ownerUsername == owner
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).map(\.model)
    }

    func createPersonalNote(title: String?, content: String) async throws -> PersonalNote {
        let entity = PersonalNoteEntity(
            ownerUsername: username,
            title: title,
            content: content
        )

        modelContext.insert(entity)
        try modelContext.save()

        return entity.model
    }

    func updatePersonalNote(id: EntityID, title: String?, content: String) async throws -> PersonalNote {
        let entity = try findPersonalNote(id: id)

        entity.title = title
        entity.content = content
        entity.updatedAt = .now

        try modelContext.save()

        return entity.model
    }

    func deletePersonalNote(id: EntityID) async throws {
        let entity = try findPersonalNote(id: id)

        modelContext.delete(entity)
        try modelContext.save()
    }

    func fetchSharedNotes() async throws -> [SharedNote] {
        let owner = username
        let currentUserId = try fetchCurrentUserId()

        let descriptor = FetchDescriptor<SharedNoteEntity>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
            .filter { note in
                note.ownerUsername == owner ||
                note.members.contains { member in
                    member.id == currentUserId
                }
            }
            .map(\.model)
    }

    func createSharedNote(
        roomId: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async throws -> SharedNote {
        let entity = SharedNoteEntity(
            ownerUsername: username,
            roomId: roomId,
            title: title,
            content: content,
            members: members
        )

        modelContext.insert(entity)
        try modelContext.save()

        return entity.model
    }

    func updateSharedNote(
        id: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async throws -> SharedNote {
        let entity = try findSharedNote(id: id)

        entity.title = title
        entity.content = content
        entity.setMembers(members)
        entity.updatedAt = .now

        try modelContext.save()

        return entity.model
    }

    func deleteSharedNote(id: EntityID) async throws {
        let entity = try findSharedNote(id: id)

        modelContext.delete(entity)
        try modelContext.save()
    }

    private func findPersonalNote(id: EntityID) throws -> PersonalNoteEntity {
        let owner = username

        let descriptor = FetchDescriptor<PersonalNoteEntity>(
            predicate: #Predicate {
                $0.id == id && $0.ownerUsername == owner
            }
        )

        guard let note = try modelContext.fetch(descriptor).first else {
            throw NSError(
                domain: "SwiftDataNotesRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Личная заметка не найдена"]
            )
        }

        return note
    }

    private func findSharedNote(id: EntityID) throws -> SharedNoteEntity {
        let owner = username
        let currentUserId = try fetchCurrentUserId()

        let descriptor = FetchDescriptor<SharedNoteEntity>(
            predicate: #Predicate {
                $0.id == id
            }
        )

        guard let note = try modelContext.fetch(descriptor).first,
              note.ownerUsername == owner || note.members.contains(where: { $0.id == currentUserId }) else {
            throw NSError(
                domain: "SwiftDataNotesRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Общая заметка не найдена"]
            )
        }

        return note
    }
    
    private func fetchCurrentUserId() throws -> EntityID {
        let owner = username

        let descriptor = FetchDescriptor<UserEntity>()

        guard let user = try modelContext.fetch(descriptor).first(where: {
            Self.normalize($0.username) == owner
        }) else {
            throw NSError(
                domain: "SwiftDataNotesRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Пользователь не найден"]
            )
        }

        return user.id
    }
    
    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }
}
