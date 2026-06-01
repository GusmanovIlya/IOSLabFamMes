import SwiftUI
import SwiftData

struct AccountView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    private let avatarSize: CGFloat = 180

    @State private var isEditingBio = false
    @State private var bioDraft = ""
    @State private var showLogoutConfirmation = false

    var body: some View {
        VStack(spacing: 12) {
            if let user = authViewModel.currentUser {
                Image(user.avatarName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.black, lineWidth: 4)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)

                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(user.bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        bioDraft = user.bio
                        isEditingBio = true
                    } label: {
                        Label("Изменить био", systemImage: "pencil")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            }

            Spacer()
                .frame(height: 24)

            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Text("Выйти из аккаунта")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .confirmationDialog(
                "Вы уверены, что хотите выйти из аккаунта?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Выйти", role: .destructive) {
                    authViewModel.logout()
                }

                Button("Отмена", role: .cancel) { }
            }
            .padding(.horizontal, 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Аккаунт")
        .sheet(isPresented: $isEditingBio) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Расскажи немного о себе")
                        .font(.headline)

                    TextEditor(text: $bioDraft)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Spacer()
                }
                .padding(20)
                .navigationTitle("Био")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            isEditingBio = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сохранить") {
                            authViewModel.updateBio(bioDraft)
                            isEditingBio = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: UserEntity.self,
        AppSessionEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    AccountView()
        .modelContainer(container)
        .environment(AuthViewModel(modelContext: container.mainContext))
}
