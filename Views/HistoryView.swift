import SwiftUI

// MARK: - History View (Liquid Glass)

struct HistoryView: View {
    @State private var history = HistoryManager.shared
    @State private var expandedSites: Set<String> = []
    @State private var selectedReport: SavedReport?
    @State private var showDeleteAll = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red:0.05,green:0.08,blue:0.18), Color(red:0.02,green:0.04,blue:0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()

                Circle().fill(Color(hex:"#00B4D8")!.opacity(0.08)).frame(width:280).blur(radius:80).offset(x:100,y:-80).ignoresSafeArea()
                Circle().fill(Color(hex:"#FF6B35")!.opacity(0.07)).frame(width:240).blur(radius:70).offset(x:-80,y:300).ignoresSafeArea()

                if history.reports.isEmpty {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 90, height: 90)
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth:1))
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 38)).foregroundStyle(.white.opacity(0.3))
                        }
                        Text("Нет сохранённых отчётов")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
                        Text("После создания акта в AR\nотчёты появятся здесь")
                            .font(.system(size: 13)).foregroundStyle(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            // Статистика
                            HStack(spacing: 10) {
                                lgStatCard("\(history.reports.count)", "Отчётов", "doc.richtext.fill", Color(hex:"#FF6B35")!)
                                lgStatCard("\(history.groupedBySite.count)", "Объектов", "antenna.radiowaves.left.and.right", Color(hex:"#00B4D8")!)
                                lgStatCard("\(history.reports.reduce(0){$0+$1.photoCount})", "Фото", "photo.fill", .green)
                            }
                            .padding(.horizontal, 16).padding(.top, 8)

                            // Папки
                            ForEach(history.groupedBySite, id: \.key) { group in
                                LGSiteFolderCard(
                                    siteKey: group.key,
                                    reports: group.reports,
                                    isExpanded: expandedSites.contains(group.key),
                                    onToggle: {
                                        withAnimation(.spring(response:0.35,dampingFraction:0.8)) {
                                            if expandedSites.contains(group.key) { expandedSites.remove(group.key) }
                                            else { expandedSites.insert(group.key) }
                                        }
                                    },
                                    onSelect: { selectedReport = $0 },
                                    onDelete: { history.delete($0) }
                                )
                                .padding(.horizontal, 16)
                            }
                            Spacer(minLength: 80)
                        }
                    }
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !history.reports.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showDeleteAll = true } label: {
                            Image(systemName: "trash").foregroundStyle(.red.opacity(0.7))
                                .frame(width: 34, height: 34).background(.ultraThinMaterial).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius:10).stroke(.red.opacity(0.2), lineWidth:1))
                        }
                    }
                }
            }
            .alert("Удалить все?", isPresented: $showDeleteAll) {
                Button("Удалить", role: .destructive) { history.deleteAll() }
                Button("Отмена", role: .cancel) {}
            }
            .sheet(item: $selectedReport) { report in
                ReportDetailView(report: report)
            }
        }
        .preferredColorScheme(.dark)
    }

    func lgStatCard(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.system(size: 10)).foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(.ultraThinMaterial).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius:16).stroke(color.opacity(0.25), lineWidth:1))
    }
}

// MARK: - Site Folder Card

struct LGSiteFolderCard: View {
    let siteKey: String
    let reports: [SavedReport]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelect: (SavedReport) -> Void
    let onDelete: (SavedReport) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex:"#FF6B35")!.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .overlay(RoundedRectangle(cornerRadius:12).stroke(Color(hex:"#FF6B35")!.opacity(0.35), lineWidth:1))
                        Image(systemName: isExpanded ? "folder.fill" : "folder")
                            .font(.system(size: 20)).foregroundStyle(Color(hex:"#FF6B35")!)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(siteKey).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        Text("\(reports.count) отчёт · \(reports.first?.dateString ?? "")")
                            .font(.system(size: 11)).foregroundStyle(.white.opacity(0.4)).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.35))
                        .rotationEffect(isExpanded ? .degrees(90) : .zero)
                        .animation(.spring(response:0.3), value: isExpanded)
                }
                .padding(16).background(.ultraThinMaterial).cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(isExpanded ? 0.2 : 0.1), lineWidth:1))
            }

            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(reports) { report in
                        HStack(spacing: 10) {
                            Button { onSelect(report) } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.07)).frame(width:38,height:38)
                                        Image(systemName: report.pdfExists ? "doc.richtext.fill" : "doc.richtext")
                                            .font(.system(size:15))
                                            .foregroundStyle(report.pdfExists ? Color(hex:"#FF6B35")! : .gray)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(report.siteName.isEmpty ? report.siteID : report.siteName)
                                            .font(.system(size:13,weight:.semibold)).foregroundStyle(.white)
                                        Text(report.dateString).font(.system(size:11)).foregroundStyle(.white.opacity(0.4))
                                        if report.latitude != nil {
                                            HStack(spacing:3) {
                                                Image(systemName:"location.fill").font(.system(size:8)).foregroundStyle(.green)
                                                Text(report.coordString).font(.system(size:8,design:.monospaced)).foregroundStyle(.white.opacity(0.4))
                                            }
                                        }
                                    }
                                    Spacer()
                                    Text("\(report.photoCount) фото").font(.system(size:10)).foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(12).background(.ultraThinMaterial).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius:12).stroke(.white.opacity(0.08), lineWidth:1))
                            }
                            Button { onDelete(report) } label: {
                                Image(systemName:"trash").font(.system(size:13)).foregroundStyle(.red.opacity(0.6))
                                    .frame(width:36,height:36).background(.red.opacity(0.08)).cornerRadius(8)
                            }
                        }
                        .padding(.leading, 14)
                    }
                }
                .transition(.opacity.combined(with:.move(edge:.top)))
            }
        }
    }
}

// MARK: - Report Detail View (Liquid Glass)

struct ReportDetailView: View {
    let report: SavedReport
    @Environment(\.dismiss) var dismiss
    @State private var showShare = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red:0.05,green:0.08,blue:0.18), Color(red:0.02,green:0.04,blue:0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Иконка
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width:90,height:90)
                                .overlay(Circle().stroke(.white.opacity(0.12), lineWidth:1))
                                .shadow(color:.black.opacity(0.3), radius:20)
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size:38)).foregroundStyle(Color(hex:"#FF6B35")!)
                        }
                        .padding(.top, 16)

                        // Данные
                        VStack(spacing:0) {
                            dr("ID сайта", report.siteID)
                            dr("Название", report.siteName)
                            dr("Дата", report.dateString)
                            dr("Специалист", report.specialistName)
                            dr("Организация", report.companyName)
                            dr("Фото", "\(report.photoCount) шт.")
                            if report.latitude != nil { dr("Координаты", report.coordString) }
                            dr("PDF", report.pdfExists ? "✅ Доступен" : "❌ Файл удалён")
                        }
                        .background(.ultraThinMaterial).cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(0.1), lineWidth:1))
                        .padding(.horizontal, 16)

                        if report.pdfExists {
                            VStack(spacing: 10) {
                                Button { showShare = true } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName:"square.and.arrow.up").font(.system(size:18))
                                        Text("Отправить PDF").fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white).frame(maxWidth:.infinity).frame(height:52)
                                    .background(Color(hex:"#FF6B35")!).cornerRadius(14)
                                    .shadow(color:Color(hex:"#FF6B35")!.opacity(0.4), radius:12, y:4)
                                }

                                HStack(spacing: 10) {
                                    Button { printPDF() } label: {
                                        HStack(spacing:6) { Image(systemName:"printer.fill"); Text("Печать").fontWeight(.semibold) }
                                            .foregroundStyle(.white).frame(maxWidth:.infinity).frame(height:48)
                                            .background(Color(red:0.15,green:0.28,blue:0.45)).cornerRadius(12)
                                    }
                                    Button { saveToFiles() } label: {
                                        HStack(spacing:6) { Image(systemName:"folder.fill"); Text("Файлы").fontWeight(.semibold) }
                                            .foregroundStyle(Color(hex:"#FF6B35")!).frame(maxWidth:.infinity).frame(height:48)
                                            .background(Color(hex:"#FF6B35")!.opacity(0.1)).cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius:12).stroke(Color(hex:"#FF6B35")!.opacity(0.3), lineWidth:1))
                                    }
                                }
                            }.padding(.horizontal, 16)
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(report.siteID.isEmpty ? "Отчёт" : report.siteID)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.confirmationAction) {
                    Button("Закрыть") { dismiss() }.foregroundStyle(Color(hex:"#FF6B35")!)
                }
            }
            .sheet(isPresented: $showShare) {
                if report.pdfExists { ShareSheet(items: [report.pdfURL]) }
            }
        }
        .preferredColorScheme(.dark)
    }

    func dr(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size:13)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value.isEmpty ? "—" : value).font(.system(size:13,weight:.medium)).foregroundStyle(.white)
        }
        .padding(.horizontal,14).padding(.vertical,10)
        .overlay(alignment:.bottom){ Divider().opacity(0.08) }
    }

    func printPDF() {
        guard report.pdfExists, let data = try? Data(contentsOf: report.pdfURL) else { showShare = true; return }
        if UIPrintInteractionController.isPrintingAvailable {
            let c = UIPrintInteractionController.shared
            let info = UIPrintInfo(dictionary: nil)
            info.outputType = .general; info.jobName = "GefestAR_\(report.siteID)"
            c.printInfo = info; c.printingItem = data; c.present(animated: true)
        } else { showShare = true }
    }

    func saveToFiles() {
        guard report.pdfExists else { return }
        let picker = UIDocumentPickerViewController(forExporting:[report.pdfURL], asCopy:true)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController { root.present(picker, animated:true) }
    }
}
