import SwiftUI
import QuickLook

// MARK: - Object Detail View

struct ObjectDetailView: View {
    let object: AMOObject
    @State private var selectedTab: DetailTab = .specs
    @State private var showAR = false
    @State private var previewURL: URL?

    enum DetailTab: String, CaseIterable {
        case specs    = "ТТХ"
        case desc     = "Описание"
        case drawings = "Чертежи"
    }

    let bg   = Color(red: 0.02, green: 0.05, blue: 0.09)
    let card = Color(red: 0.06, green: 0.10, blue: 0.16)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Заголовок с объектом
                headerSection

                // Кнопка AR
                arButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                // Табы
                tabBar

                // Контент
                ScrollView {
                    switch selectedTab {
                    case .specs:    SpecsView(object: object)
                    case .desc:     DescriptionView(object: object)
                    case .drawings: DrawingsView(object: object, previewURL: $previewURL)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showAR) {
            ARViewScreen(object: object)
        }
        .quickLookPreview($previewURL)
    }

    // MARK: Header

    var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Градиент фона
            LinearGradient(
                colors: [
                    card,
                    object.color.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                // Тип
                Text(object.type.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(object.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(object.color.opacity(0.12))
                    .cornerRadius(6)

                // Название
                Text(object.name)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Стандарт
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(object.color.opacity(0.7))
                        .font(.system(size: 12))
                    Text(object.standard)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130)
        .overlay(alignment: .bottomTrailing) {
            // Декоративная решётчатая иконка
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 70))
                .foregroundColor(object.color.opacity(0.07))
                .padding(16)
        }
    }

    // MARK: AR Button

    var arButton: some View {
        Button {
            showAR = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arkit")
                    .font(.system(size: 20, weight: .medium))
                Text("Открыть в дополненной реальности")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 18))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [object.color, object.color.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: object.color.opacity(0.4), radius: 14, y: 6)
        }
    }

    // MARK: Tab Bar

    var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? object.color : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay(alignment: .bottom) {
                            if selectedTab == tab {
                                Rectangle()
                                    .fill(object.color)
                                    .frame(height: 2)
                            }
                        }
                }
            }
        }
        .background(Color(red: 0.04, green: 0.08, blue: 0.13))
        .overlay(alignment: .bottom) {
            Divider().opacity(0.1)
        }
    }
}

// MARK: - Specs Tab

struct SpecsView: View {
    let object: AMOObject

    var specs: [(String, String)] {
        [
            ("Высота конструкции", object.height),
            ("Масса",              object.weight),
            ("База / Основание",   object.base),
            ("Полезная нагрузка",  object.payload),
            ("Ветровая нагрузка",  object.windLoad),
            ("Материал",           object.material),
            ("Стандарт",           object.standard),
        ]
    }

    var body: some View {
        VStack(spacing: 1) {
            ForEach(specs, id: \.0) { label, value in
                HStack {
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(red: 0.04, green: 0.08, blue: 0.13))
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.08)
                }
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Description Tab

struct DescriptionView: View {
    let object: AMOObject

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(object.description)
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.75))
                .lineSpacing(5)

            // Область применения
            VStack(alignment: .leading, spacing: 10) {
                Text("ОБЛАСТЬ ПРИМЕНЕНИЯ")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(object.color)

                Text("Базовые станции 4G/5G сетей НУР Телеком, Мегаком, Beeline KG. Монтаж по проектной документации ОсОО «Гефест Строй-Монтаж» в соответствии с ТЗ заказчика.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(object.color.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(object.color.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
    }
}

// MARK: - Drawings Tab

struct DrawingsView: View {
    let object: AMOObject
    @Binding var previewURL: URL?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(object.drawings) { drawing in
                Button {
                    openDrawing(drawing)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(object.color.opacity(0.1))
                                .frame(width: 46, height: 46)
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 20))
                                .foregroundColor(object.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(drawing.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(object.name)_\(drawing.fileName).pdf")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(object.color.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.04, green: 0.08, blue: 0.13))
                    .cornerRadius(13)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(object.color.opacity(0.12), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }

    func openDrawing(_ drawing: Drawing) {
        // Ищем PDF в Bundle
        if let url = Bundle.main.url(forResource: drawing.fileName, withExtension: "pdf") {
            previewURL = url
        }
        // Если PDF ещё нет в bundle — можно загрузить с сервера
    }
}
