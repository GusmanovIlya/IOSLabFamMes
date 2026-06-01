import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authViewModel: AuthViewModel?

    var body: some View {
        Group {
            if let authViewModel {
                if let user = authViewModel.currentUser {
                    MainAppView(user: user)
                        .id(user.username.lowercased())
                        .environment(authViewModel)
                } else {
                    LoginView()
                        .environment(authViewModel)
                }
            } else {
                ProgressView("Загрузка...")
            }
        }
        .task {
            if authViewModel == nil {
                authViewModel = AuthViewModel(modelContext: modelContext)
            }
        }
    }
}

private struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext

    let user: User

    @State private var notesVM: NotesViewModel?
    @State private var chatRepository: SwiftDataChatRepository?

    var body: some View {
        Group {
            if let notesVM, let chatRepository {
                TabView {
                    NotesHomeView(vm: notesVM, chatRepository: chatRepository)
                        .tabItem {
                            Label("Заметки", systemImage: "note.text")
                        }

                    ChatsHomeView(repo: chatRepository)
                        .tabItem {
                            Label("Чаты", systemImage: "bubble.left.and.bubble.right")
                        }

                    NavigationStack {
                        AccountView()
                    }
                    .tabItem {
                        Label("Аккаунт", systemImage: "person.circle")
                    }
                }
            } else {
                ProgressView("Загрузка данных...")
            }
        }
        .task(id: user.username) {
            let notesRepository = SwiftDataNotesRepository(
                modelContext: modelContext,
                username: user.username
            )

            let chatRepository = SwiftDataChatRepository(
                modelContext: modelContext,
                currentUsername: user.username
            )

            let notesVM = NotesViewModel(repository: notesRepository)
            await notesVM.reloadAll()

            self.notesVM = notesVM
            self.chatRepository = chatRepository
        }
    }
}
