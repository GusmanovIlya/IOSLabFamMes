import Foundation
import Observation

@MainActor
@Observable
final class NotesViewModel {
    private let repository: NotesRepository

    var personalNotes: [PersonalNote] = []
    var sharedNotes: [SharedNote] = []

    var state: ViewState = .loading

    init(repository: NotesRepository) {
        self.repository = repository
    }

    var hasNotes: Bool {
        !personalNotes.isEmpty || !sharedNotes.isEmpty
    }

    func reloadAll() async {
        state = .loading

        do {
            personalNotes = try await repository.fetchPersonalNotes()
            sharedNotes = try await repository.fetchSharedNotes()

            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
//    func reloadAll() async {
//        state = .loading
//
//        // Временно, только чтобы увидеть loading state
//        try? await Task.sleep(nanoseconds: 2_000_000_000)
//
//        do {
//            personalNotes = try await repository.fetchPersonalNotes()
//            sharedNotes = try await repository.fetchSharedNotes()
//
//            updateStateAfterLocalChange()
//        } catch {
//            state = .error(error.localizedDescription)
//        }
//    }
    
//    func reloadAll() async {
//        state = .loading
//
//        try? await Task.sleep(nanoseconds: 2_000_000_000)
//
//        state = .error("Тестовая ошибка загрузки данных")
//    }
    
    func loadPersonalNotes() async {
        await reloadAll()
    }

    func loadSharedNotes() async {
        await reloadAll()
    }

    func sharedNote(for roomId: EntityID) -> SharedNote? {
        sharedNotes.first(where: { $0.roomId == roomId })
    }

    func createPersonalNote(title: String?, content: String) async {
        do {
            let newNote = try await repository.createPersonalNote(
                title: title,
                content: content
            )

            personalNotes.insert(newNote, at: 0)
            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func createSharedNote(
        roomId: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async {
        do {
            let newNote = try await repository.createSharedNote(
                roomId: roomId,
                title: title,
                content: content,
                members: members
            )

            sharedNotes.removeAll { $0.roomId == roomId }
            sharedNotes.insert(newNote, at: 0)

            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func updatePersonalNote(
        id: EntityID,
        title: String?,
        content: String
    ) async {
        do {
            let updatedNote = try await repository.updatePersonalNote(
                id: id,
                title: title,
                content: content
            )

            if let index = personalNotes.firstIndex(where: { $0.id == id }) {
                personalNotes[index] = updatedNote
            }

            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func updateSharedNote(
        id: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async {
        do {
            let updatedNote = try await repository.updateSharedNote(
                id: id,
                title: title,
                content: content,
                members: members
            )

            if let index = sharedNotes.firstIndex(where: { $0.id == id }) {
                sharedNotes[index] = updatedNote
            }

            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func upsertSharedNote(
        roomId: EntityID,
        title: String?,
        content: String,
        members: [NoteMember]
    ) async {
        if let existing = sharedNote(for: roomId) {
            await updateSharedNote(
                id: existing.id,
                title: title,
                content: content,
                members: members
            )
        } else {
            await createSharedNote(
                roomId: roomId,
                title: title,
                content: content,
                members: members
            )
        }
    }

    func deletePersonalNote(id: EntityID) async {
        do {
            try await repository.deletePersonalNote(id: id)
            personalNotes.removeAll { $0.id == id }

            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func deleteSharedNote(id: EntityID) async {
        do {
            try await repository.deleteSharedNote(id: id)
            sharedNotes.removeAll { $0.id == id }

            updateStateAfterLocalChange()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func updateStateAfterLocalChange() {
        state = hasNotes ? .content : .empty
    }
    
    
}
