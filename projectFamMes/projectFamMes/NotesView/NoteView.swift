import SwiftUI

struct NoteView: View {
    let note: PersonalNote

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let title = note.title, !title.isEmpty {
                    Text(title)
                        .font(.title2.bold())
                }

                Text(note.content)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Заметка")
        .navigationBarTitleDisplayMode(.inline)
    }
}
