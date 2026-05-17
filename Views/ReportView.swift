import SwiftUI
import PhotosUI
import CoreLocation
import ImageIO

// MARK: - Report View

struct ReportView: View {
    // Параметры из AR (опциональные)
    var initialSiteID: String = ""
    var initialSiteName: String = ""
    var initialPhotos: [ReportPhoto] = []
    var initialLatitude: Double? = nil
    var initialLongitude: Double? = nil
    var initialAccuracy: Double? = nil
    var initialAltitude: Double? = nil

    @Environment(AppSettings.self) var settings
    @State private var locationManager = LocationManager()

    // Фото — главный источник данных
    @State private var geoPhotos: [ReportPhoto] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []

    // Данные — заполняются автоматически из фото или вручную
    @State private var siteID: String = ""
    @State private var siteName: String = ""
    @State private var notes: String = ""

    // GPS — берётся из фото или вручную
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var accuracy: Double? = nil
    @State private var altitude: Double? = nil
    @State private var address: String = ""
    @State private var isLoadingGPS = false

    // PDF
    @State private var pdfURL: URL? = nil
    @State private var isGenerating = false
    @State private var showShare = false

    let bg   = Color(red: 0.02, green: 0.05, blue: 0.09)
    let card = Color(red: 0.06, green: 0.10, blue: 0.16)

    var hasLocation: Bool { latitude != nil && longitude != nil }
    var coordString: String {
        guard let lat = latitude, let lon = longitude else { return "Не определены" }
        return String(format: "%.6f°, %.6f°", lat, lon)
    }

    var body: some View {
        NavigationStack {
            ZStack { bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // ── ШАГ 1: ФОТО ───────────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("1. ДОБАВЬТЕ ФОТО")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(Color(hex: "#FF6B35")!)
                                Spacer()
                                if !geoPhotos.isEmpty {
                                    Text("\(geoPhotos.count) фото добавлено")
                                        .font(.system(size: 11))
                                        .foregroundColor(.green)
                                }
                            }

                            PhotosPicker(
                                selection: $photoPickerItems,
                                maxSelectionCount: 20,
                                matching: .images
                            ) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color(hex: "#FF6B35")!.opacity(0.15)).frame(width: 48, height: 48)
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 22)).foregroundColor(Color(hex: "#FF6B35")!)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Выбрать фотографии")
                                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                        Text("GPS координаты извлекутся автоматически")
                                            .font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
                                }
                                .padding(14)
                                .background(card).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "#FF6B35")!.opacity(0.3), lineWidth: 1))
                            }
                            .onChange(of: photoPickerItems) { _, items in
                                loadPhotos(from: items)
                            }

                            // Превью фото
                            if !geoPhotos.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(geoPhotos) { photo in
                                            ZStack(alignment: .bottom) {
                                                Image(uiImage: photo.image)
                                                    .resizable().scaledToFill()
                                                    .frame(width: 110, height: 85).clipped().cornerRadius(10)

                                                // GPS бейдж
                                                HStack(spacing: 3) {
                                                    Image(systemName: photo.hasLocation ? "location.fill" : "location.slash")
                                                        .font(.system(size: 8))
                                                    Text(photo.hasLocation ? photo.shortCoord : "Нет GPS")
                                                        .font(.system(size: 7, design: .monospaced)).lineLimit(1)
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5).padding(.vertical, 2)
                                                .background(photo.hasLocation ? Color.green.opacity(0.75) : Color.black.opacity(0.65))
                                                .cornerRadius(5).padding(.bottom, 4).padding(.horizontal, 4)

                                                // Удалить
                                                Button {
                                                    geoPhotos.removeAll { $0.id == photo.id }
                                                    updateFromPhotos()
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white).font(.system(size: 18))
                                                        .background(Color.black.opacity(0.4)).clipShape(Circle())
                                                }
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── ШАГ 2: ГЕОЛОКАЦИЯ (автозаполнение) ──────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("2. ГЕОЛОКАЦИЯ")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(hasLocation ? .green : Color(hex: "#FF6B35")!)

                            if hasLocation {
                                VStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.green).font(.system(size: 16))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(coordString)
                                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.white)
                                            if let acc = accuracy {
                                                Text(String(format: "Точность: ±%.0f м", acc))
                                                    .font(.system(size: 11)).foregroundColor(.green)
                                            }
                                        }
                                        Spacer()
                                        // Источник GPS
                                        Text(geoPhotos.contains(where: { $0.hasLocation }) ? "📷 из фото" : "📡 GPS")
                                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color.white.opacity(0.08)).cornerRadius(8)
                                    }
                                    if !address.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(Color(hex: "#FF6B35")!).font(.system(size: 12))
                                            Text(address).font(.system(size: 11)).foregroundColor(.white.opacity(0.6)).lineLimit(2)
                                            Spacer()
                                        }
                                    }
                                    // Обновить
                                    Button { getCurrentGPS() } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "arrow.clockwise").font(.system(size: 11))
                                            Text("Обновить с GPS").font(.system(size: 11, weight: .medium))
                                        }.foregroundColor(Color(hex: "#00B4D8")!)
                                    }
                                }
                                .padding(14).background(card).cornerRadius(14)
                            } else {
                                HStack(spacing: 12) {
                                    Button { getCurrentGPS() } label: {
                                        HStack(spacing: 8) {
                                            if isLoadingGPS {
                                                ProgressView().tint(.white).scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "location.fill").font(.system(size: 16))
                                            }
                                            Text(isLoadingGPS ? "Определяем..." : "Получить GPS")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity).frame(height: 48)
                                        .background(Color(hex: "#00B4D8")!).cornerRadius(12)
                                    }
                                    .disabled(isLoadingGPS)

                                    Text("или добавьте фото с геометкой")
                                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }

                        // ── ШАГ 3: ДАННЫЕ ОБЪЕКТА ────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("3. ДАННЫЕ ОБЪЕКТА")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))

                            VStack(spacing: 0) {
                                inlineField(icon: "number", label: "ID сайта",
                                           placeholder: "NTDRN_41022", text: $siteID)
                                Divider().opacity(0.1).padding(.leading, 44)
                                inlineField(icon: "antenna.radiowaves.left.and.right", label: "Название",
                                           placeholder: "Bakayata_NUR_001", text: $siteName)
                                Divider().opacity(0.1).padding(.leading, 44)
                                inlineField(icon: "text.alignleft", label: "Примечание",
                                           placeholder: "Доп. информация...", text: $notes)
                            }
                            .padding(14).background(card).cornerRadius(14)
                        }

                        // ── ШАГ 4: СПЕЦИАЛИСТ ─────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("4. СПЕЦИАЛИСТ")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.35))
                                Spacer()
                                NavigationLink(destination: SettingsView()) {
                                    Text("Изменить").font(.system(size: 11)).foregroundColor(Color(hex: "#FF6B35")!)
                                }
                            }
                            VStack(spacing: 0) {
                                infoRow(label: "ФИО", value: settings.specialistName)
                                Divider().opacity(0.1)
                                infoRow(label: "Должность", value: settings.specialistRole)
                                Divider().opacity(0.1)
                                infoRow(label: "Организация", value: settings.companyName)
                            }
                            .padding(14).background(card).cornerRadius(14)
                        }

                        // ── КНОПКИ ────────────────────────────────────
                        VStack(spacing: 10) {
                            Button { generateReport() } label: {
                                HStack(spacing: 10) {
                                    if isGenerating {
                                        ProgressView().tint(.white).scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "doc.richtext.fill").font(.system(size: 20))
                                    }
                                    Text(isGenerating ? "Формируем..." : "Сформировать отчёт PDF")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                }
                                .foregroundColor(.white).padding(16)
                                .background(Color(hex: "#FF6B35")!).cornerRadius(14)
                                .shadow(color: Color(hex: "#FF6B35")!.opacity(0.4), radius: 10, y: 4)
                            }
                            .disabled(isGenerating || geoPhotos.isEmpty)
                            .opacity(geoPhotos.isEmpty ? 0.5 : 1)

                            if geoPhotos.isEmpty {
                                Text("Добавьте хотя бы одно фото для создания отчёта")
                                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                            }

                            // Кнопки после генерации
                            if let url = pdfURL {
                                HStack(spacing: 8) {
                                    actionBtn("Отправить", icon: "square.and.arrow.up",
                                              bg: Color(red: 0.15, green: 0.28, blue: 0.45)) { showShare = true }
                                    actionBtn("Печать", icon: "printer.fill",
                                              bg: Color(red: 0.12, green: 0.35, blue: 0.22)) { printReport(url: url) }
                                    actionBtn("Файлы", icon: "folder.fill",
                                              bg: Color(hex: "#FF6B35")!.opacity(0.2),
                                              fg: Color(hex: "#FF6B35")!) { saveToFiles(url: url) }
                                }
                            }

                            Button { clearForm() } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash").font(.system(size: 13))
                                    Text("Очистить").font(.system(size: 13))
                                }
                                .foregroundColor(.red.opacity(0.7))
                                .frame(maxWidth: .infinity).frame(height: 40)
                                .background(Color.red.opacity(0.06)).cornerRadius(10)
                            }
                        }
                    }
                    .padding(16).padding(.bottom, 40)
                }
            }
            .navigationTitle("Отчёт")
            .onAppear {
                if !initialSiteID.isEmpty { siteID = initialSiteID }
                if !initialSiteName.isEmpty { siteName = initialSiteName }
                if !initialPhotos.isEmpty { geoPhotos = initialPhotos }
                if let lat = initialLatitude, let lon = initialLongitude {
                    latitude = lat; longitude = lon
                    accuracy = initialAccuracy; altitude = initialAltitude
                } else if !initialPhotos.isEmpty {
                    updateFromPhotos()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShare) {
                if let url = pdfURL { ShareSheet(items: [url]) }
            }
            .onChange(of: locationManager.location) { _, loc in
                guard let loc, isLoadingGPS else { return }
                latitude = loc.coordinate.latitude
                longitude = loc.coordinate.longitude
                accuracy = loc.horizontalAccuracy
                altitude = loc.altitude
                isLoadingGPS = false
                reverseGeocode(loc)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - UI Components

    func inlineField(icon: String, label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Color(hex: "#FF6B35")!).font(.system(size: 14)).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.4))
                TextField(placeholder, text: text).foregroundColor(.white).autocorrectionDisabled()
            }
        }
        .padding(.vertical, 8)
    }

    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value.isEmpty ? "—" : value).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
        }
        .padding(.vertical, 10)
    }

    func actionBtn(_ title: String, icon: String, bg: Color, fg: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18))
                Text(title).font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(fg).frame(maxWidth: .infinity).frame(height: 56)
            .background(bg).cornerRadius(12)
        }
    }

    // MARK: - Actions

    func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var newPhotos: [ReportPhoto] = []
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { continue }
                let coord = extractGPS(from: data)
                let alt = extractAltitude(from: data)
                newPhotos.append(ReportPhoto(image: image, coordinate: coord, altitude: alt, timestamp: Date()))
            }
            await MainActor.run {
                geoPhotos.append(contentsOf: newPhotos)
                photoPickerItems = []
                updateFromPhotos()
            }
        }
    }

    func updateFromPhotos() {
        // Берём GPS из первого фото с геометкой
        if let first = geoPhotos.first(where: { $0.hasLocation }),
           let coord = first.coordinate {
            latitude = coord.latitude
            longitude = coord.longitude
            altitude = first.altitude
            accuracy = nil
            reverseGeocode(CLLocation(latitude: coord.latitude, longitude: coord.longitude))
        }
    }

    func extractGPS(from data: Data) -> CLLocationCoordinate2D? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any],
              let gps = props["{GPS}"] as? [String: Any],
              let lat = gps["Latitude"] as? Double,
              let lon = gps["Longitude"] as? Double else { return nil }
        let latRef = gps["LatitudeRef"] as? String ?? "N"
        let lonRef = gps["LongitudeRef"] as? String ?? "E"
        return CLLocationCoordinate2D(latitude: latRef == "S" ? -lat : lat, longitude: lonRef == "W" ? -lon : lon)
    }

    func extractAltitude(from data: Data) -> Double? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any],
              let gps = props["{GPS}"] as? [String: Any],
              let alt = gps["Altitude"] as? Double else { return nil }
        return alt
    }

    func getCurrentGPS() {
        isLoadingGPS = true
        locationManager.checkAuthorization()
        if let loc = locationManager.location {
            latitude = loc.coordinate.latitude
            longitude = loc.coordinate.longitude
            accuracy = loc.horizontalAccuracy
            altitude = loc.altitude
            isLoadingGPS = false
            reverseGeocode(loc)
        }
    }

    func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            guard let p = placemarks?.first else { return }
            let parts = [p.country, p.administrativeArea, p.locality, p.thoroughfare].compactMap { $0 }
            DispatchQueue.main.async { address = parts.joined(separator: ", ") }
        }
    }

    func generateReport() {
        isGenerating = true; pdfURL = nil
        DispatchQueue.global(qos: .userInitiated).async {
            let url = buildPDF()
            DispatchQueue.main.async {
                pdfURL = url
                isGenerating = false
                // Сохраняем в историю
                if let url = url {
                    saveToHistory(pdfURL: url)
                }
            }
        }
    }

    func saveToHistory(pdfURL: URL) {
        // Копируем PDF в Documents для долгосрочного хранения
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "GefestAR_\(siteID.isEmpty ? "report" : siteID)_\(Int(Date().timeIntervalSince1970)).pdf"
        let destURL = docsDir.appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: pdfURL, to: destURL)

        let report = SavedReport(
            id: UUID(),
            siteID: siteID,
            siteName: siteName,
            date: Date(),
            latitude: latitude,
            longitude: longitude,
            photoCount: geoPhotos.count,
            pdfFileName: fileName,
            specialistName: settings.specialistName,
            companyName: settings.companyName
        )
        HistoryManager.shared.save(report)
    }

    func printReport(url: URL) {
        guard let data = try? Data(contentsOf: url) else { showShare = true; return }
        if UIPrintInteractionController.isPrintingAvailable {
            let c = UIPrintInteractionController.shared
            let info = UIPrintInfo(dictionary: nil)
            info.outputType = .general; info.jobName = "GefestAR_\(siteID)"
            c.printInfo = info; c.printingItem = data; c.present(animated: true)
        } else { showShare = true }
    }

    func saveToFiles(url: URL) {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController { root.present(picker, animated: true) }
    }

    func clearForm() {
        siteID = ""; siteName = ""; notes = ""; geoPhotos = []
        latitude = nil; longitude = nil; accuracy = nil; altitude = nil
        address = ""; pdfURL = nil; photoPickerItems = []
    }

    // MARK: - PDF Builder

    func buildPDF() -> URL? {
        let W: CGFloat = 595, H: CGFloat = 842, M: CGFloat = 40
        let safe = siteID.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("GefestAR_\(safe.isEmpty ? "otchet" : safe).pdf")

        let data = UIGraphicsPDFRenderer(bounds: CGRect(x:0,y:0,width:W,height:H)).pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 0

            // Шапка
            UIColor(red:0.12,green:0.22,blue:0.39,alpha:1).setFill()
            UIBezierPath(rect:CGRect(x:0,y:0,width:W,height:56)).fill()
            UIColor(red:0.77,green:0.35,blue:0.07,alpha:1).setFill()
            UIBezierPath(rect:CGRect(x:0,y:56,width:W,height:3)).fill()
            d("ГЕФЕСТ АМО",x:M,y:12,s:15,b:true,c:.white)
            d("Акт изысканий · GefestAR",x:M,y:32,s:8,c:UIColor(white:0.7,alpha:1))
            dr(settings.companyName,y:12,s:8,c:.white,M:M,W:W)
            dr(settings.specialistName,y:28,s:8,c:UIColor(white:0.7,alpha:1),M:M,W:W)

            y=68
            dc("АКТ ВЫЕЗДНОГО ИЗЫСКАНИЯ",y:y,s:13,b:true,W:W); y+=16
            dc("места установки антенно-мачтового сооружения",y:y,s:9,c:.gray,W:W); y+=12
            hl(y:y,M:M,W:W); y+=5
            d("Дата: \(DateFormatter.localizedString(from:Date(),dateStyle:.medium,timeStyle:.short))",x:M,y:y,s:8)
            y+=5; hl(y:y,M:M,W:W,c:.lightGray,w:0.3); y+=12

            // 1. Объект
            y=sh("1. ДАННЫЕ ОБЪЕКТА",y:y,M:M,W:W)
            y=rw("ID сайта:",siteID.isEmpty ? "—":siteID,y:y,M:M,W:W)
            y=rw("Название:",siteName.isEmpty ? "—":siteName,y:y,M:M,W:W)
            if !notes.isEmpty { y=rw("Примечание:",notes,y:y,M:M,W:W) }
            y+=8

            // 2. GPS
            y=sh("2. ГЕОПРИВЯЗКА",y:y,M:M,W:W)
            if let lat=latitude, let lon=longitude {
                y=rw("Координаты (WGS-84):",String(format:"%.6f°, %.6f°",lat,lon),y:y,M:M,W:W)
                if let acc=accuracy { y=rw("Точность GPS:",String(format:"±%.0f м",acc),y:y,M:M,W:W) }
                if let alt=altitude { y=rw("Высота н.у.м.:",String(format:"%.0f м",alt),y:y,M:M,W:W) }
                if !address.isEmpty { y=rw("Адрес:",address,y:y,M:M,W:W) }
                let src = geoPhotos.contains(where:{$0.hasLocation}) ? "Из метаданных фото" : "GPS устройства"
                y=rw("Источник:",src,y:y,M:M,W:W)
            } else { y=rw("GPS:","Координаты не определены",y:y,M:M,W:W) }

            // GPS всех фото
            let withGPS = geoPhotos.filter{$0.hasLocation}
            if withGPS.count > 1 {
                y+=4; d("Геопривязка всех снимков:",x:M+3,y:y,s:8,b:true); y+=14
                for (i,p) in withGPS.enumerated() {
                    if let c=p.coordinate { y=rw("Фото \(i+1):",String(format:"%.6f°, %.6f°",c.latitude,c.longitude),y:y,M:M,W:W) }
                }
            }
            y+=8

            // 3. Фото
            if !geoPhotos.isEmpty {
                y=sh("3. ФОТОМАТЕРИАЛЫ (\(geoPhotos.count) шт.)",y:y,M:M,W:W)
                let cols=min(geoPhotos.count,2)
                let pw=(W-M*2-CGFloat(cols-1)*8)/CGFloat(cols)
                let ph=pw*0.65
                var xi=M
                for (i,photo) in geoPhotos.enumerated() {
                    if y+ph > H-60 {
                        // Подвал текущей страницы
                        UIColor(red:0.77,green:0.35,blue:0.07,alpha:1).setFill()
                        UIBezierPath(rect:CGRect(x:M,y:H-M-8,width:W-M*2,height:1)).fill()
                        ctx.beginPage(); y=M; xi=M
                    }
                    if i>0 && i%cols==0 { y+=ph+18; xi=M }
                    let rect=CGRect(x:xi,y:y,width:pw,height:ph)
                    UIColor(white:0.85,alpha:1).setStroke()
                    UIBezierPath(roundedRect:rect,cornerRadius:4).stroke()
                    // Aspect fit
                    let img = photo.image
                    let imgRatio = img.size.width / img.size.height
                    let rectRatio = pw / ph
                    var drawRect = rect.insetBy(dx:1,dy:1)
                    if imgRatio > rectRatio {
                        let h = pw / imgRatio
                        drawRect = CGRect(x: xi+1, y: y+(ph-h)/2, width: pw-2, height: h)
                    } else {
                        let w = ph * imgRatio
                        drawRect = CGRect(x: xi+(pw-w)/2, y: y+1, width: w, height: ph-2)
                    }
                    img.draw(in: drawRect)
                    if let c=photo.coordinate {
                        let gt=String(format:"📍 %.5f°, %.5f°",c.latitude,c.longitude)
                        d(gt,x:xi+3,y:y+ph+3,s:7,c:.gray)
                    }
                    xi+=pw+8
                }
                y+=ph+20
            }

            // 4. Специалист
            y=sh("4. СПЕЦИАЛИСТ",y:y,M:M,W:W)
            y=rw("ФИО:",settings.specialistName,y:y,M:M,W:W)
            y=rw("Должность:",settings.specialistRole,y:y,M:M,W:W)
            y=rw("Телефон:",settings.specialistPhone,y:y,M:M,W:W)
            y=rw("Организация:",settings.companyName,y:y,M:M,W:W)
            y+=20

            // Подписи
            let sw=(W-M*2-20)/2
            for (lbl,name,xp) in [("Специалист:",settings.specialistName,M),("Заказчик:",settings.clientRep,M+sw+20)] as [(String,String,CGFloat)] {
                d(lbl,x:xp,y:y,s:8,c:.gray)
                let p=UIBezierPath(); p.move(to:CGPoint(x:xp,y:y+14)); p.addLine(to:CGPoint(x:xp+sw,y:y+14)); p.lineWidth=0.5; UIColor.gray.setStroke(); p.stroke()
                d("(\(name.isEmpty ? "________________":name))",x:xp+8,y:y+18,s:7,c:.lightGray)
            }

            // Подвал
            UIColor(red:0.77,green:0.35,blue:0.07,alpha:1).setFill()
            UIBezierPath(rect:CGRect(x:M,y:H-M-8,width:W-M*2,height:1)).fill()
            d("Сформировано в GefestAR · \(settings.companyName)",x:M,y:H-M,s:7,c:.lightGray)
            dr("Стр. 1/1",y:H-M,s:7,c:.lightGray,M:M,W:W)
        }
        try? data.write(to:url); return url
    }

    // PDF draw helpers
    private func d(_ t:String,x:CGFloat,y:CGFloat,s:CGFloat=9,b:Bool=false,c:UIColor = .black) {
        t.draw(at:CGPoint(x:x,y:y),withAttributes:[.font:b ? UIFont.boldSystemFont(ofSize:s):UIFont.systemFont(ofSize:s),.foregroundColor:c])
    }
    private func dr(_ t:String,y:CGFloat,s:CGFloat=9,c:UIColor = .black,M:CGFloat,W:CGFloat) {
        let a:[NSAttributedString.Key:Any]=[.font:UIFont.systemFont(ofSize:s),.foregroundColor:c]
        t.draw(at:CGPoint(x:W-M-(t as NSString).size(withAttributes:a).width,y:y),withAttributes:a)
    }
    private func dc(_ t:String,y:CGFloat,s:CGFloat=10,b:Bool=false,c:UIColor = .black,W:CGFloat) {
        let a:[NSAttributedString.Key:Any]=[.font:b ? UIFont.boldSystemFont(ofSize:s):UIFont.systemFont(ofSize:s),.foregroundColor:c]
        t.draw(at:CGPoint(x:(W-(t as NSString).size(withAttributes:a).width)/2,y:y),withAttributes:a)
    }
    private func hl(y:CGFloat,M:CGFloat,W:CGFloat,c:UIColor = .lightGray,w:CGFloat=0.5) {
        let p=UIBezierPath(); p.move(to:CGPoint(x:M,y:y)); p.addLine(to:CGPoint(x:W-M,y:y)); p.lineWidth=w; c.setStroke(); p.stroke()
    }
    @discardableResult
    private func sh(_ t:String,y:CGFloat,M:CGFloat,W:CGFloat) -> CGFloat {
        UIColor(red:0.92,green:0.95,blue:0.97,alpha:1).setFill()
        UIBezierPath(rect:CGRect(x:M,y:y,width:W-M*2,height:16)).fill()
        UIColor(red:0.77,green:0.35,blue:0.07,alpha:1).setFill()
        UIBezierPath(rect:CGRect(x:M,y:y,width:3,height:16)).fill()
        d(t,x:M+7,y:y+3,s:8,b:true,c:UIColor(red:0.12,green:0.22,blue:0.39,alpha:1))
        return y+22
    }
    @discardableResult
    private func rw(_ l:String,_ v:String,y:CGFloat,M:CGFloat,W:CGFloat) -> CGFloat {
        d(l,x:M+3,y:y,s:8,c:.gray); d(v.isEmpty ? "—":v,x:M+155,y:y,s:8,b:true)
        let p=UIBezierPath(); p.move(to:CGPoint(x:M,y:y+13)); p.addLine(to:CGPoint(x:W-M,y:y+13)); p.lineWidth=0.3; UIColor(white:0.88,alpha:1).setStroke(); p.stroke()
        return y+16
    }
}

// MARK: - Report Photo Model

struct ReportPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let coordinate: CLLocationCoordinate2D?
    let altitude: Double?
    let timestamp: Date
    var hasLocation: Bool { coordinate != nil }
    var shortCoord: String {
        guard let c = coordinate else { return "—" }
        return String(format: "%.4f, %.4f", c.latitude, c.longitude)
    }
}
