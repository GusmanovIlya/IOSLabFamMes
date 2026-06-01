import Foundation

protocol NotesRepository {
    func fetchPersonalNotes() async throws -> [PersonalNote]
    func createPersonalNote(title: String?, content: String) async throws -> PersonalNote
    func updatePersonalNote(id: EntityID, title: String?, content: String) async throws -> PersonalNote
    func deletePersonalNote(id: EntityID) async throws
    
    func fetchSharedNotes() async throws -> [SharedNote]
    func createSharedNote(roomId: EntityID, title: String?, content: String, members: [NoteMember]) async throws -> SharedNote
    func updateSharedNote(id: EntityID, title: String?, content: String, members: [NoteMember]) async throws -> SharedNote
    func deleteSharedNote(id: EntityID) async throws
}
