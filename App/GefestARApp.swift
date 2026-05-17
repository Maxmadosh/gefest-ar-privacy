import SwiftUI

@main
struct GefestARApp: App {
    @StateObject private var authManager = AuthManager()
    @State private var appSettings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environment(appSettings)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(AppSettings.self) var settings

    var body: some View {
        Group {
            if settings.isFirstLaunch {
                FirstLaunchView()
            } else if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoggedIn)
        .animation(.easeInOut(duration: 0.3), value: settings.isFirstLaunch)
    }
}
