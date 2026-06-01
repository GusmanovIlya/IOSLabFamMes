import SwiftUI
import SwiftData

@main
struct projectFamMesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserEntity.self,
            ChatEntity.self,
            MessageEntity.self,
            PersonalNoteEntity.self,
            SharedNoteEntity.self,
            AppSessionEntity.self
        ])
    }
}
