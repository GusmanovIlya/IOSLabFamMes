import SwiftUI

struct NotesHomeView: View {
    @State var vm: NotesViewModel
    let chatRepository: ChatRepository

    @State private var showCreatePersonal = false
    @State private var showCreateShared = false

    @State private var editingPersonalNote: PersonalNote?
    @State private var editingSharedNote: SharedNote?

    var body: some View {
        NavigationStack {
            List {
                content
            }
            .listStyle(.plain)
            .navigationTitle("Заметки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCreatePersonal = true
                        } label: {
                            Label("Личная заметка", systemImage: "person")
                        }

                        Button {
                            showCreateShared = true
                        } label: {
                            Label("Общая заметка", systemImage: "person.2")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreatePersonal) {
                NotesEditView(vm: vm)
            }
            .sheet(isPresented: $showCreateShared) {
                SharedNotesEditView(vm: vm, chatRepository: chatRepository)
            }
            .sheet(item: $editingPersonalNote) { note in
                NotesEditView(vm: vm, note: note)
            }
            .sheet(item: $editingSharedNote) { note in
                SharedNotesEditView(
                    vm: vm,
                    chatRepository: chatRepository,
                    note: note
                )
            }
        }
        .task {
            await vm.reloadAll()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .loading:
            HStack {
                Spacer()
                ProgressView("Загрузка заметок...")
                Spacer()
            }
            .padding(.vertical, 40)
            .listRowSeparator(.hidden)

        case .empty:
            emptySection

        case .content:
            personalSection
            sharedSection

        case .error(let message):
            ErrorStateView(message: message) {
                Task {
                    await vm.reloadAll()
                }
            }
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var personalSection: some View {
        if !vm.personalNotes.isEmpty {
            Section("Личные") {
                ForEach(vm.personalNotes) { note in
                    personalRow(note)
                }
            }
        }
    }

    @ViewBuilder
    private var sharedSection: some View {
        if !vm.sharedNotes.isEmpty {
            Section("Общие") {
                ForEach(vm.sharedNotes) { note in
                    sharedRow(note)
                }
            }
        }
    }

    @ViewBuilder
    private var emptySection: some View {
        ContentUnavailableView(
            "Нет заметок",
            systemImage: "note.text",
            description: Text("Создай первую личную или общую заметку")
        )
        .listRowSeparator(.hidden)
    }

    private func personalRow(_ note: PersonalNote) -> some View {
        NoteCardView(
            title: note.title ?? "Без названия",
            content: note.content,
            updatedAt: note.updatedAt,
            membersCount: nil
        )
        .overlay {
            NavigationLink(destination: NoteView(note: note)) {
                EmptyView()
            }
            .opacity(0)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await vm.deletePersonalNote(id: note.id)
                }
            } label: {
                Label("Удалить", systemImage: "trash")
            }

            Button {
                editingPersonalNote = note
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private func sharedRow(_ note: SharedNote) -> some View {
        NoteCardView(
            title: note.title ?? "Без названия",
            content: note.content,
            updatedAt: note.updatedAt,
            membersCount: note.members.count
        )
        .overlay {
            NavigationLink(destination: SharedNoteView(note: note)) {
                EmptyView()
            }
            .opacity(0)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await vm.deleteSharedNote(id: note.id)
                }
            } label: {
                Label("Удалить", systemImage: "trash")
            }

            Button {
                editingSharedNote = note
            } label: {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct NoteCardView: View {
    let title: String
    let content: String
    let updatedAt: Date
    let membersCount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Text(updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let membersCount {
                    Label("\(membersCount)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Не удалось загрузить данные")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Повторить", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
    }
}
