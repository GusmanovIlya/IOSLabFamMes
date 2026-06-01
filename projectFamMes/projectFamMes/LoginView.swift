import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isRegisterMode = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 32)

                    header
                    fields
                    errorBlock
                    mainButton
                    modeSwitcher

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: isRegisterMode ? "person.badge.plus" : "person.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text(isRegisterMode ? "Создание аккаунта" : "Вход")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(isRegisterMode ? "Заполни данные и начни пользоваться FamMes" : "Войди в свой аккаунт")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var fields: some View {
        VStack(spacing: 14) {
            if isRegisterMode {
                TextField("Имя", text: $name)
                    .textContentType(.name)
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            TextField("Логин", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.username)
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            SecureField("Пароль", text: $password)
                .textContentType(isRegisterMode ? .newPassword : .password)
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if isRegisterMode {
                SecureField("Повтори пароль", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var errorBlock: some View {
        if !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var mainButton: some View {
        Button {
            handleAuth()
        } label: {
            Text(isRegisterMode ? "Создать аккаунт" : "Войти")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var modeSwitcher: some View {
        Button {
            withAnimation {
                isRegisterMode.toggle()
                errorMessage = ""
                password = ""
                confirmPassword = ""
            }
        } label: {
            Text(isRegisterMode ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                .font(.subheadline)
        }
    }

    

    private func handleAuth() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Заполни логин и пароль"
            return
        }

        guard password.count >= 4 else {
            errorMessage = "Пароль должен быть минимум 4 символа"
            return
        }

        if isRegisterMode {
            guard !trimmedName.isEmpty else {
                errorMessage = "Укажи имя"
                return
            }

            guard password == confirmPassword else {
                errorMessage = "Пароли не совпадают"
                return
            }

            let success = authViewModel.register(
                name: trimmedName,
                username: trimmedUsername,
                password: password
            )

            errorMessage = success ? "" : "Такой логин уже существует"
        } else {
            let success = authViewModel.login(
                username: trimmedUsername,
                password: password
            )

            errorMessage = success ? "" : "Неверный логин или пароль"
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: UserEntity.self,
        AppSessionEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    LoginView()
        .modelContainer(container)
        .environment(AuthViewModel(modelContext: container.mainContext))
}
