import SwiftUI
import UniformTypeIdentifiers

// MARK: - First Launch View (Liquid Glass)

struct FirstLaunchView: View {
    @Environment(AppSettings.self) var settings
    @State private var step = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red:0.05,green:0.08,blue:0.18), Color(red:0.02,green:0.04,blue:0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            Circle().fill(Color(hex:"#FF6B35")!.opacity(0.1)).frame(width:300).blur(radius:80).offset(x:-80,y:-150).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule().fill(i <= step ? Color(hex:"#FF6B35")! : Color.white.opacity(0.15)).frame(height: 4)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 60).padding(.bottom, 32)

                Group {
                    switch step {
                    case 0: LGWelcomeStep()
                    case 1: LGCompanyStep()
                    case 2: LGSpecialistStep(onFinish: { settings.isFirstLaunch = false })
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(insertion: .move(edge:.trailing).combined(with:.opacity), removal: .move(edge:.leading).combined(with:.opacity)))

                Spacer()

                HStack(spacing: 12) {
                    if step > 0 {
                        Button("Назад") { withAnimation { step -= 1 } }
                            .foregroundStyle(.white.opacity(0.5)).frame(width: 80, height: 52)
                            .background(.ultraThinMaterial).cornerRadius(14)
                    }
                    if step < 2 {
                        Button { withAnimation { step += 1 } } label: {
                            Text(step == 0 ? "Начать" : "Далее")
                                .fontWeight(.semibold).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(Color(hex:"#FF6B35")!).cornerRadius(14)
                                .shadow(color: Color(hex:"#FF6B35")!.opacity(0.4), radius: 12, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 48)
            }
        }
    }
}

struct LGWelcomeStep: View {
    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 130, height: 130)
                    .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 52, weight: .light)).foregroundStyle(Color(hex:"#FF6B35")!)
            }
            VStack(spacing: 10) {
                Text("GefestAR").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Выездные изыскания АМС").font(.system(size: 16)).foregroundStyle(.white.opacity(0.5))
            }
            VStack(spacing: 10) {
                lgFeatureRow(icon: "arkit", text: "AR-визуализация конструкций")
                lgFeatureRow(icon: "location.fill", text: "GPS мачты фиксируется при размещении")
                lgFeatureRow(icon: "doc.richtext.fill", text: "Автоматический акт PDF")
                lgFeatureRow(icon: "folder.fill", text: "История по объектам")
            }.padding(.horizontal, 24)
        }
    }
}

func lgFeatureRow(icon: String, text: String) -> some View {
    HStack(spacing: 14) {
        Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color(hex:"#FF6B35")!)
            .frame(width: 32, height: 32).background(Color(hex:"#FF6B35")!.opacity(0.12)).cornerRadius(8)
        Text(text).font(.system(size: 14)).foregroundStyle(.white.opacity(0.8))
        Spacer()
    }
    .padding(12).background(.ultraThinMaterial).cornerRadius(12)
    .overlay(RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.1), lineWidth:1))
}

struct LGCompanyStep: View {
    @Environment(AppSettings.self) var settings
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Организация").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                    Text("Данные появятся в шапке актов").font(.system(size: 14)).foregroundStyle(.white.opacity(0.45))
                }
                VStack(spacing: 12) {
                    @Bindable var s = settings
                    LGField(label: "Ваша организация *", placeholder: "ОсОО «Гефест Строй-Монтаж»", text: $s.companyName)
                    LGField(label: "Заказчик", placeholder: "ООО «НУР Телеком»", text: $s.clientName)
                    LGField(label: "Представитель заказчика", placeholder: "ФИО", text: $s.clientRep)
                }
            }.padding(.horizontal, 24)
        }
    }
}

struct LGSpecialistStep: View {
    @Environment(AppSettings.self) var settings
    let onFinish: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Специалист").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                    Text("Ваши данные для актов").font(.system(size: 14)).foregroundStyle(.white.opacity(0.45))
                }
                VStack(spacing: 12) {
                    @Bindable var s = settings
                    LGField(label: "ФИО *", placeholder: "Иванов И.И.", text: $s.specialistName)
                    LGField(label: "Должность", placeholder: "Инженер-изыскатель", text: $s.specialistRole)
                    LGField(label: "Телефон", placeholder: "+996 700 000 000", text: $s.specialistPhone, keyboard: .phonePad)
                }
                if settings.isConfigured {
                    Button(action: onFinish) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Готово!").fontWeight(.semibold)
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color(hex:"#06D6A0")!).cornerRadius(14)
                        .shadow(color: Color(hex:"#06D6A0")!.opacity(0.4), radius: 12, y: 4)
                    }
                }
            }.padding(.horizontal, 24)
        }
    }
}

// MARK: - Settings View (Liquid Glass)

struct SettingsView: View {
    @Environment(AppSettings.self) var settings
    @State private var showReset = false
    @State private var showObjectManager = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red:0.05,green:0.08,blue:0.18), Color(red:0.02,green:0.04,blue:0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                Circle().fill(Color(hex:"#FF6B35")!.opacity(0.08)).frame(width:250).blur(radius:70).offset(x:-80,y:100).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        @Bindable var s = settings

                        // Профиль
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(.ultraThinMaterial).frame(width: 60, height: 60)
                                    .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                                Image(systemName: "person.fill").font(.system(size: 26)).foregroundStyle(Color(hex:"#FF6B35")!)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(settings.specialistName.isEmpty ? "Специалист" : settings.specialistName)
                                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                                Text(settings.companyName.isEmpty ? "Компания не указана" : settings.companyName)
                                    .font(.system(size: 13)).foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                        }
                        .padding(16).background(.ultraThinMaterial).cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(0.12), lineWidth:1))
                        .padding(.horizontal, 16).padding(.top, 8)

                        // Организация
                        LGSection(title: "ОРГАНИЗАЦИЯ") {
                            LGField(label: "Ваша организация", placeholder: "ОсОО «...»", text: $s.companyName)
                            LGField(label: "Заказчик", placeholder: "ООО «НУР Телеком»", text: $s.clientName)
                            LGField(label: "Представитель заказчика", placeholder: "ФИО", text: $s.clientRep)
                        }

                        // Специалист
                        LGSection(title: "СПЕЦИАЛИСТ") {
                            LGField(label: "ФИО", placeholder: "Иванов И.И.", text: $s.specialistName)
                            LGField(label: "Должность", placeholder: "Инженер-изыскатель", text: $s.specialistRole)
                            LGField(label: "Телефон", placeholder: "+996 700 000 000", text: $s.specialistPhone, keyboard: .phonePad)
                        }

                        // Управление объектами
                        LGSection(title: "ОБЪЕКТЫ АМС") {
                            Button {
                                showObjectManager = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10).fill(Color(hex:"#FF6B35")!.opacity(0.15)).frame(width: 36, height: 36)
                                        Image(systemName: "cube.box.fill").foregroundStyle(Color(hex:"#FF6B35")!).font(.system(size: 16))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Управление объектами").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                        Text("Добавить, редактировать, импорт USDZ").font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.3))
                                }
                            }
                        }

                        // Версия
                        HStack {
                            Image(systemName: "info.circle").foregroundStyle(.white.opacity(0.3))
                            Text("GefestAR · ОсОО «Гефест Строй-Монтаж»")
                                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.3))
                            Spacer()
                        }.padding(.horizontal, 20)

                        // Сброс
                        Button { showReset = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Сбросить настройки")
                            }
                            .foregroundStyle(.red.opacity(0.8)).frame(maxWidth: .infinity).frame(height: 46)
                            .background(Color.red.opacity(0.08)).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius:12).stroke(.red.opacity(0.2), lineWidth:1))
                            .padding(.horizontal, 16)
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .alert("Сбросить настройки?", isPresented: $showReset) {
                Button("Сбросить", role: .destructive) { settings.reset() }
                Button("Отмена", role: .cancel) {}
            }
            .sheet(isPresented: $showObjectManager) {
                ObjectManagerView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Object Manager View

struct ObjectManagerView: View {
    @State private var manager = CustomObjectManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showAddSheet = false
    @State private var editingObject: CustomAMOObject?
    @State private var editingBuiltIn: AMOObject?
    @State private var showDeleteConfirm = false
    @State private var objectToDelete: CustomAMOObject?

    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        // Встроенные объекты
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ВСТРОЕННЫЕ ОБЪЕКТЫ (\(AMOObject.sampleData.count))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))

                            ForEach(AMOObject.sampleData) { obj in
                                Button { editingBuiltIn = obj } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8).fill(obj.color.opacity(0.15)).frame(width: 38, height: 38)
                                            Text("AR").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(obj.color)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(obj.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                            Text("\(obj.folder) · \(obj.height)").font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
                                        }
                                        Spacer()
                                        Image(systemName: "pencil.circle").foregroundStyle(Color(hex:"#FF6B35")!).font(.system(size: 18))
                                    }
                                }
                                .padding(12).background(.ultraThinMaterial).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.08), lineWidth:1))
                            }
                        }
                        .padding(.horizontal, 16)

                        // Мои объекты
                        if !manager.objects.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("МОИ ОБЪЕКТЫ (\(manager.objects.count))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))

                                ForEach(manager.objects) { obj in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(hex: obj.colorHex)?.opacity(0.15) ?? Color.orange.opacity(0.15))
                                                .frame(width: 38, height: 38)
                                            Text("AR").font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundStyle(Color(hex: obj.colorHex) ?? .orange)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(obj.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                            Text("\(obj.folder.isEmpty ? "Мои объекты" : obj.folder) · \(obj.height.isEmpty ? "—" : obj.height)")
                                                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
                                        }
                                        Spacer()
                                        Button { editingObject = obj } label: {
                                            Image(systemName: "pencil").foregroundStyle(Color(hex:"#FF6B35")!).font(.system(size: 14))
                                                .frame(width: 32, height: 32).background(Color(hex:"#FF6B35")!.opacity(0.1)).cornerRadius(8)
                                        }
                                        Button {
                                            objectToDelete = obj
                                            showDeleteConfirm = true
                                        } label: {
                                            Image(systemName: "trash").foregroundStyle(.red.opacity(0.7)).font(.system(size: 13))
                                                .frame(width: 32, height: 32).background(Color.red.opacity(0.08)).cornerRadius(8)
                                        }
                                    }
                                    .padding(12).background(.ultraThinMaterial).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.08), lineWidth:1))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        Spacer(minLength: 80)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Объекты АМС")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }.foregroundStyle(.white.opacity(0.5))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus").foregroundStyle(Color(hex:"#FF6B35")!)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddObjectView(onSave: { obj in
                    manager.add(obj)
                })
            }
            .sheet(item: $editingObject) { obj in
                AddObjectView(existingObject: obj, onSave: { updated in
                    manager.update(updated)
                })
            }
            .sheet(item: $editingBuiltIn) { obj in
                EditBuiltInObjectView(object: obj)
            }
            .alert("Удалить объект?", isPresented: $showDeleteConfirm) {
                Button("Удалить", role: .destructive) {
                    if let obj = objectToDelete { manager.delete(obj) }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Add / Edit Object View

struct AddObjectView: View {
    var existingObject: CustomAMOObject? = nil
    let onSave: (CustomAMOObject) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var folder: String = "Мои объекты"
    @State private var type: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var base: String = ""
    @State private var windLoad: String = ""
    @State private var payload: String = ""
    @State private var material: String = ""
    @State private var description: String = ""
    @State private var usdzFileName: String = ""
    @State private var colorHex: String = "#FF6B35"

    @State private var showFilePicker = false
    @State private var usdzImported = false
    @State private var importError: String? = nil

    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)
    let folders = ["Мои объекты", "Трёхгранные мачты", "Башни решётчатые", "Мобильные мачты", "Мачты трубчатые", "Кровельные конструкции"]
    let colors = ["#FF6B35", "#00B4D8", "#06D6A0", "#E76F51", "#F59E0B", "#8B5CF6"]

    var isEditing: Bool { existingObject != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // USDZ импорт
                        VStack(alignment: .leading, spacing: 10) {
                            Text("USDZ МОДЕЛЬ").font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.35))

                            Button { showFilePicker = true } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(usdzImported || !usdzFileName.isEmpty ? Color.green.opacity(0.15) : Color(hex:"#FF6B35")!.opacity(0.15))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: usdzImported || !usdzFileName.isEmpty ? "checkmark.circle.fill" : "cube.box")
                                            .font(.system(size: 22))
                                            .foregroundStyle(usdzImported || !usdzFileName.isEmpty ? .green : Color(hex:"#FF6B35")!)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(usdzImported || !usdzFileName.isEmpty ? "USDZ загружен" : "Импортировать USDZ")
                                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                        Text(usdzFileName.isEmpty ? "Выберите файл .usdz из Files" : usdzFileName + ".usdz")
                                            .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(14).background(.ultraThinMaterial).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius:14).stroke(
                                    (usdzImported || !usdzFileName.isEmpty) ? Color.green.opacity(0.4) : Color(hex:"#FF6B35")!.opacity(0.3),
                                    lineWidth: 1))
                            }

                            if let error = importError {
                                Text("⚠️ \(error)").font(.system(size: 11)).foregroundStyle(.red.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)

                        // Основные данные
                        LGSection(title: "НАЗВАНИЕ И ТИП") {
                            LGField(label: "Название *", placeholder: "Трёхгранная мачта 24м", text: $name)
                            LGField(label: "Тип конструкции", placeholder: "Мачта решётчатая трёхгранная", text: $type)
                        }

                        // Папка
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ПАПКА").font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(folders, id: \.self) { f in
                                        Button { folder = f } label: {
                                            Text(f).font(.system(size: 12))
                                                .foregroundStyle(folder == f ? .white : .white.opacity(0.6))
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(folder == f ? Color(hex:"#FF6B35")! : Color.white.opacity(0.06))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Технические характеристики
                        LGSection(title: "ТЕХНИЧЕСКИЕ ХАРАКТЕРИСТИКИ") {
                            LGField(label: "Высота", placeholder: "24 м", text: $height)
                            LGField(label: "Масса", placeholder: "1 850 кг", text: $weight)
                            LGField(label: "База основания", placeholder: "4.2 × 4.2 м", text: $base)
                            LGField(label: "Ветровая нагрузка", placeholder: "до 160 км/ч", text: $windLoad)
                            LGField(label: "Полезная нагрузка", placeholder: "до 1 200 кг", text: $payload)
                            LGField(label: "Материал", placeholder: "Ст3сп, горячее цинкование", text: $material)
                        }

                        // Описание
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ОПИСАНИЕ").font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
                            TextEditor(text: $description)
                                .foregroundStyle(.white).scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(12).background(.white.opacity(0.07)).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius:10).stroke(.white.opacity(0.1), lineWidth:1))
                        }
                        .padding(.horizontal, 16)

                        // Цвет
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ЦВЕТ МЕТКИ").font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
                            HStack(spacing: 12) {
                                ForEach(colors, id: \.self) { hex in
                                    Button { colorHex = hex } label: {
                                        ZStack {
                                            Circle().fill(Color(hex: hex) ?? .orange).frame(width: 36, height: 36)
                                            if colorHex == hex {
                                                Circle().stroke(.white, lineWidth: 3).frame(width: 36, height: 36)
                                                Image(systemName: "checkmark").foregroundStyle(.white).font(.system(size: 12, weight: .bold))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Кнопка сохранить
                        Button {
                            saveObject()
                        } label: {
                            Text(isEditing ? "Сохранить изменения" : "Добавить объект")
                                .fontWeight(.semibold).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(name.isEmpty ? Color.gray.opacity(0.4) : Color(hex:"#FF6B35")!)
                                .cornerRadius(14)
                                .shadow(color: name.isEmpty ? .clear : Color(hex:"#FF6B35")!.opacity(0.4), radius: 10, y: 4)
                        }
                        .disabled(name.isEmpty)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isEditing ? "Редактировать" : "Новый объект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(.white.opacity(0.5))
                }
            }
            .fileImporter(isPresented: $showFilePicker,
                          allowedContentTypes: [UTType(filenameExtension: "usdz") ?? .data],
                          allowsMultipleSelection: false) { result in
                handleUSDZImport(result)
            }
            .onAppear { loadExisting() }
        }
        .preferredColorScheme(.dark)
    }

    func loadExisting() {
        guard let obj = existingObject else { return }
        name = obj.name; folder = obj.folder; type = obj.type
        height = obj.height; weight = obj.weight; base = obj.base
        windLoad = obj.windLoad; payload = obj.payload; material = obj.material
        description = obj.description; usdzFileName = obj.usdzFileName; colorHex = obj.colorHex
    }

    func handleUSDZImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let rawName = url.deletingPathExtension().lastPathComponent
            if let saved = CustomObjectManager.shared.saveUSDZ(from: url, named: rawName) {
                usdzFileName = saved
                usdzImported = true
                importError = nil
                if name.isEmpty { name = rawName.replacingOccurrences(of: "_", with: " ") }
            } else {
                importError = "Не удалось импортировать файл"
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    func saveObject() {
        let obj = CustomAMOObject(
            id: existingObject?.id ?? UUID().uuidString,
            name: name, folder: folder, type: type,
            usdzFileName: usdzFileName,
            height: height, weight: weight, base: base,
            windLoad: windLoad, payload: payload, material: material,
            description: description, colorHex: colorHex
        )
        onSave(obj)
        dismiss()
    }
}

// MARK: - Liquid Glass Components

struct LGSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 20)
            VStack(spacing: 12) { content }
                .padding(16).background(.ultraThinMaterial).cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(0.1), lineWidth:1))
                .padding(.horizontal, 16)
        }
    }
}

struct LGField: View {
    let label: String; let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
            TextField(placeholder, text: $text)
                .foregroundStyle(.white).keyboardType(keyboard).autocorrectionDisabled()
                .padding(12).background(.white.opacity(0.07)).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius:10).stroke(.white.opacity(0.1), lineWidth:1))
        }
    }
}

// Legacy compat
struct SetupField: View {
    let label: String; let placeholder: String
    @Binding var text: String
    var required: Bool = false
    var keyboard: UIKeyboardType = .default
    var body: some View { LGField(label: label, placeholder: placeholder, text: $text, keyboard: keyboard) }
}
struct SettingsSection<Content: View>: View {
    let title: String; @ViewBuilder let content: Content
    var body: some View { LGSection(title: title) { content } }
}

// MARK: - Edit Built-In Object View

// Расширение для Identifiable

struct EditBuiltInObjectView: View {
    let object: AMOObject
    @Environment(\.dismiss) var dismiss
    @State private var manager = CustomObjectManager.shared

    // Редактируемые поля
    @State private var name: String = ""
    @State private var folder: String = ""
    @State private var type: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var base: String = ""
    @State private var windLoad: String = ""
    @State private var payload: String = ""
    @State private var material: String = ""
    @State private var description: String = ""
    @State private var colorHex: String = ""
    @State private var usdzFileName: String = ""
    @State private var showFilePicker = false
    @State private var usdzImported = false

    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)
    let folders = ["Трёхгранные мачты","Башни решётчатые","Мобильные мачты","Мачты трубчатые","Кровельные конструкции","Мои объекты"]
    let colors = ["#FF6B35","#00B4D8","#06D6A0","#E76F51","#F59E0B","#8B5CF6"]

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // USDZ
                        Button { showFilePicker = true } label: {
                            HStack(spacing:12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius:10)
                                        .fill(usdzImported ? Color.green.opacity(0.15) : Color(hex:"#FF6B35")!.opacity(0.15))
                                        .frame(width:48, height:48)
                                    Image(systemName: usdzImported ? "checkmark.circle.fill" : "cube.box")
                                        .font(.system(size:22))
                                        .foregroundStyle(usdzImported ? .green : Color(hex:"#FF6B35")!)
                                }
                                VStack(alignment:.leading, spacing:3) {
                                    Text(usdzImported ? "USDZ обновлён" : "Заменить USDZ файл")
                                        .font(.system(size:15, weight:.semibold)).foregroundStyle(.white)
                                    Text(usdzFileName.isEmpty ? object.usdzFileName : usdzFileName)
                                        .font(.system(size:11)).foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName:"chevron.right").foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(14).background(.ultraThinMaterial).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius:14).stroke(
                                usdzImported ? Color.green.opacity(0.4) : Color(hex:"#FF6B35")!.opacity(0.3), lineWidth:1))
                        }
                        .padding(.horizontal, 16)

                        LGSection(title: "НАЗВАНИЕ И ТИП") {
                            LGField(label:"Название", placeholder:object.name, text:$name)
                            LGField(label:"Тип", placeholder:object.type, text:$type)
                        }

                        VStack(alignment:.leading, spacing:10) {
                            Text("ПАПКА").font(.system(size:11, design:.monospaced)).foregroundStyle(.white.opacity(0.35))
                            ScrollView(.horizontal, showsIndicators:false) {
                                HStack(spacing:8) {
                                    ForEach(folders, id:\.self) { f in
                                        Button { folder = f } label: {
                                            Text(f).font(.system(size:12))
                                                .foregroundStyle(folder == f ? .white : .white.opacity(0.6))
                                                .padding(.horizontal,12).padding(.vertical,6)
                                                .background(folder == f ? Color(hex:"#FF6B35")! : Color.white.opacity(0.06))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal, 16)

                        LGSection(title: "ХАРАКТЕРИСТИКИ") {
                            LGField(label:"Высота", placeholder:object.height, text:$height)
                            LGField(label:"Масса", placeholder:object.weight, text:$weight)
                            LGField(label:"База", placeholder:object.base, text:$base)
                            LGField(label:"Ветровая нагрузка", placeholder:object.windLoad, text:$windLoad)
                            LGField(label:"Нагрузка антенн", placeholder:object.payload, text:$payload)
                            LGField(label:"Материал", placeholder:object.material, text:$material)
                        }

                        VStack(alignment:.leading, spacing:10) {
                            Text("ОПИСАНИЕ").font(.system(size:11, design:.monospaced)).foregroundStyle(.white.opacity(0.35))
                            TextEditor(text:$description)
                                .foregroundStyle(.white).scrollContentBackground(.hidden)
                                .frame(height:100).padding(12)
                                .background(.white.opacity(0.07)).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius:10).stroke(.white.opacity(0.1), lineWidth:1))
                        }.padding(.horizontal, 16)

                        VStack(alignment:.leading, spacing:10) {
                            Text("ЦВЕТ МЕТКИ").font(.system(size:11, design:.monospaced)).foregroundStyle(.white.opacity(0.35))
                            HStack(spacing:12) {
                                ForEach(colors, id:\.self) { hex in
                                    Button { colorHex = hex } label: {
                                        ZStack {
                                            Circle().fill(Color(hex:hex) ?? .orange).frame(width:36, height:36)
                                            if colorHex == hex {
                                                Circle().stroke(.white, lineWidth:3).frame(width:36, height:36)
                                                Image(systemName:"checkmark").foregroundStyle(.white).font(.system(size:12, weight:.bold))
                                            }
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal, 16)

                        Button { saveOverride() } label: {
                            Text("Сохранить изменения")
                                .fontWeight(.semibold).foregroundStyle(.white)
                                .frame(maxWidth:.infinity).frame(height:52)
                                .background(Color(hex:"#FF6B35")!).cornerRadius(14)
                                .shadow(color:Color(hex:"#FF6B35")!.opacity(0.4), radius:10, y:4)
                        }.padding(.horizontal, 16)

                        Spacer(minLength:40)
                    }.padding(.top, 16)
                }
            }
            .navigationTitle("Редактировать: \(object.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(.white.opacity(0.5))
                }
            }
            .fileImporter(isPresented:$showFilePicker,
                          allowedContentTypes:[UTType(filenameExtension:"usdz") ?? .data],
                          allowsMultipleSelection:false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    let rawName = url.deletingPathExtension().lastPathComponent
                    if let saved = CustomObjectManager.shared.saveUSDZ(from:url, named:rawName) {
                        usdzFileName = saved; usdzImported = true
                    }
                }
            }
            .onAppear { loadFields() }
        }
        .preferredColorScheme(.dark)
    }

    func loadFields() {
        name = object.name; folder = object.folder; type = object.type
        height = object.height; weight = object.weight; base = object.base
        windLoad = object.windLoad; payload = object.payload; material = object.material
        description = object.description; colorHex = object.colorHex
        usdzFileName = object.usdzFileName
    }

    func saveOverride() {
        // Сохраняем переопределение как кастомный объект с тем же ID
        let override = CustomAMOObject(
            id: object.id + "_override",
            name: name.isEmpty ? object.name : name,
            folder: folder.isEmpty ? object.folder : folder,
            type: type.isEmpty ? object.type : type,
            usdzFileName: usdzFileName.isEmpty ? object.usdzFileName : usdzFileName,
            height: height.isEmpty ? object.height : height,
            weight: weight.isEmpty ? object.weight : weight,
            base: base.isEmpty ? object.base : base,
            windLoad: windLoad.isEmpty ? object.windLoad : windLoad,
            payload: payload.isEmpty ? object.payload : payload,
            material: material.isEmpty ? object.material : material,
            description: description.isEmpty ? object.description : description,
            colorHex: colorHex.isEmpty ? object.colorHex : colorHex
        )
        // Удаляем старый override если есть
        if let existing = manager.objects.first(where: { $0.id == override.id }) {
            manager.delete(existing)
        }
        manager.add(override)
        dismiss()
    }
}
