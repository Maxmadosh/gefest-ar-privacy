import SwiftUI

// MARK: - Home View (Liquid Glass)

struct HomeView: View {
    @State private var searchText = ""
    @State private var expandedFolders: Set<String> = []
    @State private var selectedObject: AMOObject?
    @State private var showDetail = false
    @State private var showQRScanner = false
    // Наблюдаем за изменениями — когда меняются объекты, вид обновляется
    @State private var objectManager = CustomObjectManager.shared

    var filteredObjects: [AMOObject] {
        guard !searchText.isEmpty else { return [] }
        return objectManager.allObjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.localizedCaseInsensitiveContains(searchText) ||
            $0.folder.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Фон — градиент Liquid Glass
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.18),
                        Color(red: 0.02, green: 0.04, blue: 0.12),
                        Color(red: 0.08, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Акцентные пятна света
                GeometryReader { geo in
                    Circle()
                        .fill(Color(hex: "#FF6B35")!.opacity(0.12))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: -50, y: -100)

                    Circle()
                        .fill(Color(hex: "#00B4D8")!.opacity(0.08))
                        .frame(width: 250, height: 250)
                        .blur(radius: 70)
                        .offset(x: geo.size.width - 100, y: geo.size.height * 0.4)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Поиск
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.5))
                            TextField("Поиск объектов...", text: $searchText)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14).frame(height: 46)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        if !searchText.isEmpty {
                            // Результаты поиска
                            VStack(spacing: 8) {
                                ForEach(filteredObjects) { obj in
                                    LGObjectRow(object: obj) { selectedObject = obj; showDetail = true }
                                        .padding(.horizontal, 16)
                                }
                            }
                        } else {
                            // Папки
                            ForEach(AMOObject.folders, id: \.self) { folder in
                                LGFolderCard(
                                    folder: folder,
                                    isExpanded: expandedFolders.contains(folder),
                                    onToggle: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            if expandedFolders.contains(folder) {
                                                expandedFolders.remove(folder)
                                            } else {
                                                expandedFolders.insert(folder)
                                            }
                                        }
                                    },
                                    onSelect: { obj in
                                        selectedObject = obj
                                        showDetail = true
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Объекты АМО")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showQRScanner = true } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .navigationDestination(isPresented: $showDetail) {
                if let obj = selectedObject { ObjectDetailView(object: obj) }
            }
            .fullScreenCover(isPresented: $showQRScanner) { QRScannerScreen() }
        }
    }
}

// MARK: - Liquid Glass Folder Card

struct LGFolderCard: View {
    let folder: String
    var allObjects: [AMOObject] = AMOObject.sampleData
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelect: (AMOObject) -> Void

    var objects: [AMOObject] { allObjects.filter { $0.folder == folder } }

    var body: some View {
        VStack(spacing: 0) {
            // Заголовок папки
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#FF6B35")!.opacity(0.2))
                            .frame(width: 46, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#FF6B35")!.opacity(0.4), lineWidth: 1)
                            )
                        Image(systemName: isExpanded ? "folder.fill" : "folder")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(hex: "#FF6B35")!)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(folder)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(objects.count) объект(ов)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .rotationEffect(isExpanded ? .degrees(90) : .zero)
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(isExpanded ? 0.25 : 0.12), lineWidth: 1)
                )
            }

            // Объекты
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(objects) { obj in
                        LGObjectRow(object: obj) { onSelect(obj) }
                            .padding(.leading, 14)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Liquid Glass Object Row

struct LGObjectRow: View {
    let object: AMOObject
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(object.color.opacity(0.18))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(object.color.opacity(0.35), lineWidth: 1)
                        )
                    Text("AR")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(object.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(object.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(object.type) · \(object.height)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(object.color.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Search Bar (legacy compat)

struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.4))
            TextField("Поиск...", text: $text).foregroundStyle(.white)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 14).frame(height: 46)
        .background(.ultraThinMaterial)
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.1), lineWidth: 1))
    }
}
