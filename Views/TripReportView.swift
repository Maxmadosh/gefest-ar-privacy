import SwiftUI
import PDFKit
import PhotosUI

// MARK: - Trip Report View

struct TripReportView: View {
    let trip: FieldTrip
    let settings: AppSettings
    @Environment(\.dismiss) var dismiss

    @State private var pdfURL: URL?
    @State private var isGenerating = true
    @State private var showShare = false
    @State private var photoItem: PhotosPickerItem?
    @State private var overridePhoto: UIImage?
    @State private var showSaveSuccess = false

    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)

    var currentPhoto: UIImage? { overridePhoto ?? trip.primaryPhoto }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── PDF Preview ─────────────────────────────────────
                    if isGenerating {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView().scaleEffect(1.5).tint(Color(hex: "#FF6B35")!)
                            Text("Формируем акт...").foregroundColor(.white.opacity(0.6)).font(.system(size: 15))
                        }
                        Spacer()
                    } else if let url = pdfURL {
                        PDFKitView(url: url)
                            .cornerRadius(8)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.62)
                            .padding(.horizontal, 10)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }

                    // ── Панель кнопок ────────────────────────────────────
                    if !isGenerating {
                        VStack(spacing: 8) {

                            // Сменить фото
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                HStack(spacing: 8) {
                                    Image(systemName: currentPhoto != nil ? "photo.fill" : "photo.badge.plus")
                                        .font(.system(size: 15))
                                    Text(currentPhoto != nil ? "Заменить AR-фото" : "Добавить фото мачты")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    if currentPhoto != nil {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                            Text("Добавлено").font(.system(size: 11)).foregroundColor(.green)
                                        }
                                    }
                                }
                                .foregroundColor(Color(hex: "#00B4D8")!)
                                .padding(.horizontal, 14).frame(height: 44)
                                .background(Color(hex: "#00B4D8")!.opacity(0.1)).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#00B4D8")!.opacity(0.3), lineWidth: 1))
                            }

                            // Три главных кнопки
                            HStack(spacing: 8) {
                                // Печать
                                Button { printPDF() } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "printer.fill").font(.system(size: 20))
                                        Text("Печать").font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                                    .background(Color(red: 0.15, green: 0.28, blue: 0.45)).cornerRadius(12)
                                }

                                // Сохранить в Files
                                Button { saveToFiles() } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "folder.fill").font(.system(size: 20))
                                        Text("Файлы").font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                                    .background(Color(red: 0.12, green: 0.35, blue: 0.22)).cornerRadius(12)
                                }

                                // Отправить
                                Button { showShare = true } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.up").font(.system(size: 20))
                                        Text("Отправить").font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                                    .background(Color(hex: "#FF6B35")!).cornerRadius(12)
                                    .shadow(color: Color(hex: "#FF6B35")!.opacity(0.4), radius: 6, y: 3)
                                }
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color(red: 0.04, green: 0.08, blue: 0.13))
                    }
                }
            }
            .navigationTitle("Акт — \(trip.siteID)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }.foregroundColor(.white.opacity(0.5))
                }
            }
            .onAppear { generatePDF() }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let item,
                       let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        overridePhoto = image
                        isGenerating = true
                        generatePDF()
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                if let url = pdfURL { ShareSheet(items: [url]) }
            }
            .overlay {
                if showSaveSuccess {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("PDF сохранён").fontWeight(.semibold)
                        }
                        .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(.ultraThinMaterial).cornerRadius(20).padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    func generatePDF() {
        DispatchQueue.global(qos: .userInitiated).async {
            let url = ReportPDFGenerator.generate(
                trip: trip,
                settings: settings,
                arPhoto: currentPhoto
            )
            DispatchQueue.main.async {
                self.pdfURL = url
                self.isGenerating = false
            }
        }
    }

    func printPDF() {
        guard let url = pdfURL,
              let data = try? Data(contentsOf: url),
              UIPrintInteractionController.isPrintingAvailable else {
            // Если печать недоступна — показываем share sheet
            showShare = true
            return
        }
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "GefestAR — \(trip.siteID)"
        info.duplex = .longEdge
        controller.printInfo = info
        controller.printingItem = data
        controller.present(animated: true, completionHandler: nil)
    }

    func saveToFiles() {
        guard let url = pdfURL else { return }
        // Показываем системный диалог сохранения
        let controller = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(controller, animated: true)
        }
    }
}

// MARK: - PDF Kit View

struct PDFKitView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url)
        view.backgroundColor = UIColor(red: 0.02, green: 0.05, blue: 0.09, alpha: 1)
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let url = uiView.document?.documentURL, url != self.url {
            uiView.document = PDFDocument(url: self.url)
        }
    }
}

// MARK: - Report PDF Generator

struct ReportPDFGenerator {

    static func generate(trip: FieldTrip, settings: AppSettings, arPhoto: UIImage? = nil) -> URL? {
        let pageW: CGFloat = 595
        let pageH: CGFloat = 842
        let M:     CGFloat = 40

        let safe = trip.siteID.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GefestAR_\(safe).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = M

            // ШАПКА
            UIColor(red: 0.12, green: 0.22, blue: 0.39, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageW, height: 54)).fill()
            UIColor(red: 0.77, green: 0.35, blue: 0.07, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 54, width: pageW, height: 3)).fill()

            t("ГЕФЕСТ АМО", x: M, y: 12, s: 15, bold: true, c: .white)
            t("Акт выездных изысканий · GefestAR", x: M, y: 30, s: 8, c: UIColor(white: 0.7, alpha: 1))
            tr(settings.companyName, x: M, y: 12, s: 8, c: .white, pw: pageW)
            tr("Субподрядчик ООО «НУР Телеком»", x: M, y: 26, s: 8, c: UIColor(white: 0.7, alpha: 1), pw: pageW)

            y = 66

            tc("АКТ ВЫЕЗДНЫХ ИЗЫСКАНИЙ", y: y, s: 13, bold: true, pw: pageW)
            y += 16
            tc("места установки антенно-мачтового сооружения", y: y, s: 9, c: .gray, pw: pageW)
            y += 10
            hl(y: y, M: M, pw: pageW, c: .lightGray, w: 0.4)
            y += 5
            t("Документ № \(trip.docNumber)", x: M, y: y, s: 8)
            tr("Дата: \(trip.dateString)", x: M, y: y, s: 8, pw: pageW)
            y += 5
            hl(y: y, M: M, pw: pageW, c: .lightGray, w: 0.3)
            y += 10

            // 1. ДАННЫЕ ВЫЕЗДА
            y = sh("1. ДАННЫЕ ВЫЕЗДА", y: y, M: M, pw: pageW)
            y = rw("ID сайта:", trip.siteID, y: y, M: M, pw: pageW)
            y = rw("Название сайта:", trip.siteName, y: y, M: M, pw: pageW)
            y = rw("Регион:", trip.region, y: y, M: M, pw: pageW)
            y = rw("Район / Адрес:", "\(trip.district) \(trip.address)", y: y, M: M, pw: pageW)
            y = rw("Цель:", trip.purpose.title, y: y, M: M, pw: pageW)
            y += 6

            // 2. КОНСТРУКЦИЯ
            if let obj = trip.selectedObject {
                y = sh("2. КОНСТРУКЦИЯ — \(obj.name)", y: y, M: M, pw: pageW)
                y = rw("Тип:", "\(obj.name)  \(obj.type)", y: y, M: M, pw: pageW)
                y = rw("Высота:", obj.height, y: y, M: M, pw: pageW)
                y = rw("База основания:", obj.base, y: y, M: M, pw: pageW)
                y = rw("Нагрузка (антенны):", obj.payload, y: y, M: M, pw: pageW)
                y = rw("Масса:", obj.weight, y: y, M: M, pw: pageW)
                y = rw("Стандарт:", obj.standard, y: y, M: M, pw: pageW)
                y += 6
            }

            // 3. GPS
            y = sh("3. GPS-ДАННЫЕ И ГЕОПРИВЯЗКА", y: y, M: M, pw: pageW)
            y = rw("Широта (WGS-84):", trip.latString, y: y, M: M, pw: pageW)
            y = rw("Долгота (WGS-84):", trip.lonString, y: y, M: M, pw: pageW)
            y = rw("Точность GPS:", trip.accuracyString, y: y, M: M, pw: pageW)
            y = rw("Высота над уровнем моря:", trip.altitudeString, y: y, M: M, pw: pageW)
            y = rw("Дата и время замера:", trip.gpsTimeString, y: y, M: M, pw: pageW)
            y = rw("Адрес:", trip.addressResolved.isEmpty ? "—" : trip.addressResolved, y: y, M: M, pw: pageW)
            y += 6

            // 4. AR ФОТО
            y = sh("4. AR-ВИЗУАЛИЗАЦИЯ МАЧТЫ НА МЕСТЕ УСТАНОВКИ", y: y, M: M, pw: pageW)

            let photoW = pageW - M * 2
            let photoH = photoW * 0.52

            if let photo = arPhoto {
                let rect = CGRect(x: M, y: y, width: photoW, height: photoH)
                UIColor(white: 0.85, alpha: 1).setStroke()
                UIBezierPath(roundedRect: rect, cornerRadius: 4).stroke()
                photo.draw(in: rect.insetBy(dx: 1, dy: 1))

                // Водяной знак
                let wmAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 8),
                    .foregroundColor: UIColor.white,
                    .backgroundColor: UIColor.black.withAlphaComponent(0.6)
                ]
                " AR · GefestAR  |  \(trip.photoWatermark) ".draw(
                    at: CGPoint(x: M + 5, y: y + 5), withAttributes: wmAttrs)

                // GPS координаты на фото (если есть геопривязка)
                if let geoPhoto = trip.primaryGeoPhoto, geoPhoto.hasLocation {
                    let gpsAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 8),
                        .foregroundColor: UIColor.white,
                        .backgroundColor: UIColor(red: 0, green: 0.5, blue: 0.8, alpha: 0.8)
                    ]
                    " 📍 \(geoPhoto.coordString) ".draw(
                        at: CGPoint(x: M + 5, y: y + photoH - 18), withAttributes: gpsAttrs)
                }
            } else {
                UIColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 1).setFill()
                UIBezierPath(roundedRect: CGRect(x: M, y: y, width: photoW, height: photoH), cornerRadius: 4).fill()
                tc("Место для AR-фото мачты", y: y + photoH/2 - 8, s: 10, c: .gray, pw: pageW)
                tc("(добавьте фото из приложения GefestAR)", y: y + photoH/2 + 6, s: 8, c: .lightGray, pw: pageW)
            }
            y += photoH + 8

            // Таблица фото с координатами
            if !trip.geoPhotos.isEmpty {
                y = sh("5. ГЕОПРИВЯЗКА СНИМКОВ", y: y, M: M, pw: pageW)
                let cw: [CGFloat] = [20, 80, 140, 90, 100]
                thdr(["№", "Время", "Координаты", "Точность", "Высота н.у.м."],
                     widths: cw, x: M, y: y, pw: pageW)
                y += 16
                for (i, geo) in trip.geoPhotos.enumerated() {
                    let row = [
                        "\(i + 1)",
                        geo.timeString,
                        geo.hasLocation ? geo.coordString : "—",
                        geo.accuracy != nil ? String(format: "±%.0f м", geo.accuracy!) : "—",
                        geo.altitude != nil ? String(format: "%.0f м", geo.altitude!) : "—"
                    ]
                    trow(row, widths: cw, x: M, y: y)
                    y += 14
                }
                y += 6
            }

            // 6. СПЕЦИАЛИСТ
            let sIdx = trip.geoPhotos.isEmpty ? "5" : "6"
            y = sh("\(sIdx). СПЕЦИАЛИСТ", y: y, M: M, pw: pageW)
            y = rw("ФИО:", settings.specialistName, y: y, M: M, pw: pageW)
            y = rw("Должность:", settings.specialistRole, y: y, M: M, pw: pageW)
            y = rw("Телефон:", settings.specialistPhone, y: y, M: M, pw: pageW)
            y = rw("Организация:", settings.companyName, y: y, M: M, pw: pageW)
            y += 16

            // ПОДПИСИ
            let sw = (pageW - M*2 - 20) / 2
            for (label, name, xPos) in [
                ("Специалист:", settings.specialistName, M),
                ("Представитель заказчика:", settings.clientRep, M + sw + 20)
            ] as [(String, String, CGFloat)] {
                t(label, x: xPos, y: y, s: 8, c: .gray)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: xPos, y: y + 14))
                path.addLine(to: CGPoint(x: xPos + sw, y: y + 14))
                path.lineWidth = 0.5; UIColor.gray.setStroke(); path.stroke()
                t("(\(name.isEmpty ? "________________" : name))", x: xPos + 8, y: y + 18, s: 7, c: .lightGray)
            }

            // ПОДВАЛ
            UIColor(red: 0.77, green: 0.35, blue: 0.07, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: M, y: pageH - M - 10, width: pageW - M*2, height: 1.5)).fill()
            t("Сформировано в GefestAR  |  \(settings.companyName)", x: M, y: pageH - M, s: 7, c: .lightGray)
            tr("\(trip.docNumber)  |  Стр. 1/1", x: M, y: pageH - M, s: 7, c: .lightGray, pw: pageW)
        }

        try? data.write(to: url)
        return url
    }

    // MARK: - Helpers

    private static func t(_ text: String, x: CGFloat, y: CGFloat, s: CGFloat = 9,
                            bold: Bool = false, c: UIColor = .black) {
        text.draw(at: CGPoint(x: x, y: y), withAttributes: [
            .font: bold ? UIFont.boldSystemFont(ofSize: s) : UIFont.systemFont(ofSize: s),
            .foregroundColor: c
        ])
    }
    private static func tr(_ text: String, x: CGFloat, y: CGFloat, s: CGFloat = 9,
                             bold: Bool = false, c: UIColor = .black, pw: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: bold ? UIFont.boldSystemFont(ofSize: s) : UIFont.systemFont(ofSize: s),
            .foregroundColor: c
        ]
        let w = (text as NSString).size(withAttributes: attrs).width
        text.draw(at: CGPoint(x: pw - x - w, y: y), withAttributes: attrs)
    }
    private static func tc(_ text: String, y: CGFloat, s: CGFloat = 10,
                             bold: Bool = false, c: UIColor = .black, pw: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: bold ? UIFont.boldSystemFont(ofSize: s) : UIFont.systemFont(ofSize: s),
            .foregroundColor: c
        ]
        let w = (text as NSString).size(withAttributes: attrs).width
        text.draw(at: CGPoint(x: (pw - w) / 2, y: y), withAttributes: attrs)
    }
    private static func hl(y: CGFloat, M: CGFloat, pw: CGFloat, c: UIColor = .lightGray, w: CGFloat = 0.5) {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: M, y: y)); p.addLine(to: CGPoint(x: pw - M, y: y))
        p.lineWidth = w; c.setStroke(); p.stroke()
    }
    @discardableResult
    private static func sh(_ text: String, y: CGFloat, M: CGFloat, pw: CGFloat) -> CGFloat {
        UIColor(red: 0.92, green: 0.95, blue: 0.97, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: M, y: y, width: pw - M*2, height: 16)).fill()
        UIColor(red: 0.77, green: 0.35, blue: 0.07, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: M, y: y, width: 3, height: 16)).fill()
        t(text, x: M + 7, y: y + 3, s: 8, bold: true, c: UIColor(red: 0.12, green: 0.22, blue: 0.39, alpha: 1))
        return y + 22
    }
    @discardableResult
    private static func rw(_ label: String, _ value: String,
                             y: CGFloat, M: CGFloat, pw: CGFloat) -> CGFloat {
        t(label, x: M + 3, y: y, s: 8, c: .gray)
        t(value.isEmpty ? "—" : value, x: M + 155, y: y, s: 8, bold: true)
        hl(y: y + 13, M: M, pw: pw, c: UIColor(white: 0.88, alpha: 1), w: 0.3)
        return y + 16
    }
    private static func thdr(_ labels: [String], widths: [CGFloat], x: CGFloat, y: CGFloat, pw: CGFloat) {
        UIColor(red: 0.12, green: 0.22, blue: 0.39, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: x, y: y, width: widths.reduce(0, +), height: 16)).fill()
        var xi = x
        for (i, label) in labels.enumerated() {
            label.draw(at: CGPoint(x: xi + 3, y: y + 3), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 7.5),
                .foregroundColor: UIColor.white
            ])
            xi += widths[i]
        }
    }
    private static func trow(_ values: [String], widths: [CGFloat], x: CGFloat, y: CGFloat) {
        var xi = x
        for (i, val) in values.enumerated() {
            val.draw(at: CGPoint(x: xi + 3, y: y + 2), withAttributes: [
                .font: UIFont.systemFont(ofSize: 7.5),
                .foregroundColor: UIColor.black
            ])
            xi += widths[i]
        }
        let p = UIBezierPath()
        p.move(to: CGPoint(x: x, y: y + 13))
        p.addLine(to: CGPoint(x: x + widths.reduce(0, +), y: y + 13))
        p.lineWidth = 0.3; UIColor(white: 0.88, alpha: 1).setStroke(); p.stroke()
    }
}
