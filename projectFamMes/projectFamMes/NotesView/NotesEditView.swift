import SwiftUI

struct NotesEditView: View {
    @Environment(\.dismiss) private var dismiss

    let vm: NotesViewModel
    let note: PersonalNote?

    @State private var title: String
    @State private var content: String

    init(vm: NotesViewModel, note: PersonalNote? = nil) {
        self.vm = vm
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Заголовок") {
                    TextField("Введите заголовок", text: $title)
                }

                Section("Текст") {
                    TextEditor(text: $content)
                        .frame(minHeight: 220)
                }
            }
            .navigationTitle(note == nil ? "Новая заметка" : "Редактировать")
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
                            if let note {
                                await vm.updatePersonalNote(
                                    id: note.id,
                                    title: title.isEmpty ? nil : title,
                                    content: content
                                )
                            } else {
                                await vm.createPersonalNote(
                                    title: title.isEmpty ? nil : title,
                                    content: content
                                )
                            }

                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

