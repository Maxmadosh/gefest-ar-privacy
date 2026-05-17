import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Объекты", systemImage: "square.grid.2x2") }
                .tag(0)
            HistoryView()
                .tabItem { Label("История", systemImage: "folder.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(Color(hex: "#FF6B35")!)
        .preferredColorScheme(.dark)
    }
}
