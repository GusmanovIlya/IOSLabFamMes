import SwiftUI

struct SharedNotesEditView: View {
    @Environment(\.dismiss) private var dismiss

    let vm: NotesViewModel
    let chatRepository: ChatRepository
    let note: SharedNote?

    let presetRoomId: EntityID?
    let presetMembers: [NoteMember]
    let presetTitle: String?

    @State private var title: String
    @State private var content: String

    @State private var availableUsers: [UserSummary] = []
    @State private var selectedMembers: [NoteMember] = []

    init(
        vm: NotesViewModel,
        chatRepository: ChatRepository,
        note: SharedNote? = nil,
        presetRoomId: EntityID? = nil,
        presetMembers: [NoteMember] = [],
        presetTitle: String? = nil
    ) {
        self.vm = vm
        self.chatRepository = chatRepository
        self.note = note
        self.presetRoomId = presetRoomId
        self.presetMembers = presetMembers
        self.presetTitle = presetTitle

        _title = State(initialValue: note?.title ?? presetTitle ?? "")
        _content = State(initialValue: note?.content ?? "")
        _selectedMembers = State(initialValue: note?.members ?? presetMembers)
    }

    private var participantsText: String {
        let names = selectedMembers.map(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "Нажми, чтобы выбрать участников" : names.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DisclosureGroup {
                        if availableUsers.isEmpty {
                            ContentUnavailableView(
                                "Нет доступных участников",
                                systemImage: "person.crop.circle.badge.exclamationmark",
                                description: Text("Здесь будут только люди, с которыми уже есть чат")
                            )
                        } else {
                            ForEach(availableUsers) { user in
                                Button {
                                    toggleUser(user)
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.name)
                                                .foregroundStyle(.primary)

                                            Text("@\(user.username)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if isSelected(user) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Участники")
                                .font(.headline)

                            Text(participantsText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Заголовок") {
                    TextField("Введите заголовок", text: $title)
                }

                Section("Текст") {
                    TextEditor(text: $content)
                        .frame(minHeight: 220)
                }
            }
            .navigationTitle(note == nil ? "Новая общая" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            let finalTitle = trimmedTitle.isEmpty ? nil : trimmedTitle

                            let finalMembers = normalizedMembers()

                            if let note {
                                await vm.updateSharedNote(
                                    id: note.id,
                                    title: finalTitle,
                                    content: content,
                                    members: finalMembers
                                )
                            } else {
                                let roomId = presetRoomId ?? UUID().uuidString

                                await vm.createSharedNote(
                                    roomId: roomId,
                                    title: finalTitle,
                                    content: content,
                                    members: finalMembers
                                )
                            }

                            dismiss()
                        }
                    }
                    .disabled(
                        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        selectedMembers.isEmpty
                    )
                }
            }
            .task {
                await loadUsers()
            }
        }
    }

    private func loadUsers() async {
        do {
            availableUsers = try await chatRepository.fetchKnownUsers()

            if selectedMembers.isEmpty, let note {
                selectedMembers = note.members
            } else if selectedMembers.isEmpty {
                selectedMembers = presetMembers
            }
        } catch {
            availableUsers = []
        }
    }

    private func toggleUser(_ user: UserSummary) {
        let member = NoteMember(id: user.id, name: user.name)

        if let index = selectedMembers.firstIndex(where: { $0.id == member.id }) {
            selectedMembers.remove(at: index)
        } else {
            selectedMembers.append(member)
        }
    }

    private func isSelected(_ user: UserSummary) -> Bool {
        selectedMembers.contains(where: { $0.id == user.id })
    }

    private func normalizedMembers() -> [NoteMember] {
        var result = selectedMembers

        if !result.contains(where: { $0.id == "me" }) {
            result.insert(NoteMember(id: "me", name: "Вы"), at: 0)
        }

        return result
    }
}
