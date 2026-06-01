import SwiftUI

struct SharedNoteView: View {
    let note: SharedNote

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let title = note.title, !title.isEmpty {
                    Text(title)
                        .font(.title2.bold())
                }

                Text(note.content)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))

                    Spacer()

                    Label("\(note.members.count)", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Заметка")
        .navigationBarTitleDisplayMode(.inline)
    }
}
