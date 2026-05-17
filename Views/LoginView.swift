import SwiftUI

struct LoginView: View {
    // Получаем доступ к вашему менеджеру авторизации
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 30) {
            Text("Добро пожаловать в GefestAR")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: {
                // При нажатии меняем статус на "в сети"
                withAnimation {
                    authManager.isLoggedIn = true
                }
            }) {
                Text("Войти")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}
