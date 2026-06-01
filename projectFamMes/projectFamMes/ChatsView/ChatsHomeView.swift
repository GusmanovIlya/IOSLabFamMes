import SwiftUI

struct ChatsHomeView: View {
    private let repo: any ChatRepository
    @State private var vm: ChatsHomeViewModel

    init(repo: any ChatRepository) {
        self.repo = repo
        _vm = State(initialValue: ChatsHomeViewModel(repo: repo))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if vm.hasSearchQuery, !vm.filteredUsers.isEmpty {
                        usersSection
                    }

                    chatsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Чаты")
            .searchable(text: $vm.searchText, prompt: "Поиск по имени или username")
        }
        .task {
            await vm.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatsDidChange)) { _ in
            Task {
                await vm.load()
            }
        }
    }

    private var usersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Пользователи")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(vm.filteredUsers) { user in
                NavigationLink {
                    let chat = vm.chatForFoundUser(user)

                    ChatView(
                        chat: chat,
                        vm: ChatViewModel(roomId: chat.id, repo: repo),
                        chatRepository: repo
                    )
                } label: {
                    FoundUserRowView(user: user)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !vm.filteredChats.isEmpty || !vm.hasSearchQuery {
                Text(vm.hasSearchQuery ? "Чаты" : "")
                    .font(.headline)
                    .padding(.horizontal, 4)
                    .opacity(vm.hasSearchQuery ? 1 : 0)

                ForEach(vm.filteredChats) { chat in
                    NavigationLink {
                        ChatView(
                            chat: chat,
                            vm: ChatViewModel(roomId: chat.id, repo: repo),
                            chatRepository: repo
                        )
                    } label: {
                        ChatRowView(chat: chat)
                    }
                    .buttonStyle(.plain)
                }
            }

            if vm.hasSearchQuery && vm.filteredChats.isEmpty && vm.filteredUsers.isEmpty {
                ContentUnavailableView(
                    "Ничего не найдено",
                    systemImage: "magnifyingglass",
                    description: Text("Попробуй другое имя или username")
                )
                .padding(.top, 40)
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            Image(chat.avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(chat.name)
                        .font(.headline)

                    Spacer()

                    Text(chat.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(chat.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct FoundUserRowView: View {
    let user: UserSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(user.avatarName)
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(user.name)
                    .font(.headline)

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Начать переписку")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    ChatsHomeView(repo: MockChatRepository())
}

#Preview("Chat Row") {
    ChatRowView(
        chat: Chat(
            id: "room_gusmanovilya",
            avatar: "avatar1",
            name: "Илья",
            username: "GusmanovIlya",
            lastMessage: "Сделать вход для пользователей",
            time: "12:45"
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Found User Row") {
    FoundUserRowView(
        user: UserSummary(
            id: "user_kirill",
            name: "Кирилл",
            username: "kirill"
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
