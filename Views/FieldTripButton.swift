import SwiftUI
import CoreLocation
import MapKit
import Photos
import Observation

// MARK: - Field Trip Button

struct FieldTripButton: View {
    @Binding var showTrip: Bool
    var body: some View {
        Button { showTrip = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color(hex: "#FF6B35")!).frame(width: 44, height: 44)
                    Image(systemName: "car.fill").font(.system(size: 18)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Начать выезд").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text("Данные сайта → AR → Акт PDF").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(LinearGradient(colors: [Color(hex: "#FF6B35")!.opacity(0.2), Color(hex: "#FF6B35")!.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#FF6B35")!.opacity(0.3), lineWidth: 1))
        }
    }
}

// MARK: - Field Trip Form

struct FieldTripFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppSettings.self) var settings
    @State var trip = FieldTrip()
    @State var locationManager = LocationManager()

    @State private var step = 0
    @State private var showARScreen = false
    @State private var showReport = false

    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    TripProgressBar(step: step)
                        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)

                    TabView(selection: $step) {
                        SiteDataStep(trip: trip)
                            .tag(0)
                        ObjectSelectStep(trip: trip)
                            .tag(1)
                        TripSummaryStep(
                            trip: trip,
                            settings: settings,
                            locationManager: locationManager,
                            showAR: $showARScreen,
                            showReport: $showReport
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: step)

                    HStack(spacing: 12) {
                        if step > 0 {
                            Button("Назад") { withAnimation { step -= 1 } }
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 80, height: 50)
                                .background(Color.white.opacity(0.06)).cornerRadius(12)
                        }
                        if step < 2 {
                            Button { withAnimation { step += 1 } } label: {
                                Text(step == 0 ? "Далее — Выбор объекта" : "Далее — Сводка")
                                    .fontWeight(.semibold).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(canProceed ? Color(hex: "#FF6B35")! : Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                            }.disabled(!canProceed)
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 30).padding(.top, 8)
                }
            }
            .navigationTitle(stepTitle).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }.foregroundColor(.white.opacity(0.5))
                }
            }
            .fullScreenCover(isPresented: $showARScreen) {
                if let obj = trip.selectedObject {
                    ARViewScreenWithTrip(object: obj, trip: trip, locationManager: locationManager)
                }
            }
            .sheet(isPresented: $showReport) {
                TripReportView(trip: trip, settings: settings)
            }
            .onAppear { syncGPS() }
            .onChange(of: locationManager.location) { _, loc in
                guard let loc else { return }
                trip.latitude = loc.coordinate.latitude
                trip.longitude = loc.coordinate.longitude
                trip.accuracy = loc.horizontalAccuracy
                trip.altitude = loc.altitude
                trip.gpsTimestamp = Date()
            }
            .onChange(of: locationManager.address) { _, addr in
                trip.addressResolved = addr
            }
        }
        .preferredColorScheme(.dark)
    }

    func syncGPS() {
        if let loc = locationManager.location {
            trip.latitude = loc.coordinate.latitude
            trip.longitude = loc.coordinate.longitude
            trip.accuracy = loc.horizontalAccuracy
            trip.altitude = loc.altitude
            trip.gpsTimestamp = Date()
            trip.addressResolved = locationManager.address
        }
    }

    var canProceed: Bool {
        switch step {
        case 0: return !trip.siteID.isEmpty && !trip.siteName.isEmpty
        case 1: return trip.selectedObject != nil
        default: return true
        }
    }
    var stepTitle: String {
        ["Данные сайта", "Выбор объекта АМС", "Сводка выезда"][step]
    }
}

// MARK: - Progress Bar

struct TripProgressBar: View {
    let step: Int
    let steps = ["Сайт", "Объект", "Выезд"]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                HStack(spacing: 0) {
                    ZStack {
                        Circle().fill(i <= step ? Color(hex: "#FF6B35")! : Color.white.opacity(0.1)).frame(width: 28, height: 28)
                        if i < step {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        } else {
                            Text("\(i+1)").font(.system(size: 11, weight: .bold))
                                .foregroundColor(i == step ? .white : .white.opacity(0.3))
                        }
                    }
                    Text(steps[i]).font(.system(size: 10))
                        .foregroundColor(i <= step ? .white : .white.opacity(0.3)).padding(.leading, 4)
                    if i < steps.count - 1 {
                        Rectangle().fill(i < step ? Color(hex: "#FF6B35")! : Color.white.opacity(0.1))
                            .frame(height: 1.5).padding(.horizontal, 6)
                    }
                }
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 4)
        .background(Color.white.opacity(0.04)).cornerRadius(20)
    }
}

// MARK: - Step 0: Site Data

struct SiteDataStep: View {
    @Bindable var trip: FieldTrip
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                FormCard(title: "ИДЕНТИФИКАЦИЯ САЙТА") {
                    TripField(label: "ID сайта *", placeholder: "NTDRNPEXP2026_41022RR07", text: $trip.siteID)
                    TripField(label: "Название сайта *", placeholder: "Bakayata_NUR_001", text: $trip.siteName)
                }
                FormCard(title: "МЕСТОПОЛОЖЕНИЕ") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("РЕГИОН").font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.3))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(FieldTrip.kyrgyzRegions, id: \.self) { region in
                                    Button { trip.region = region } label: {
                                        Text(region).font(.system(size: 11))
                                            .foregroundColor(trip.region == region ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(trip.region == region ? Color(hex: "#FF6B35")! : Color.white.opacity(0.06))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    TripField(label: "Район / Айыл өкмөтү", placeholder: "Бакайатинский район", text: $trip.district)
                    TripField(label: "Ориентир / Адрес", placeholder: "2 км к северу от с. Бакайата", text: $trip.address)
                }
                FormCard(title: "ЦЕЛЬ ВЫЕЗДА") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(TripPurpose.allCases, id: \.self) { purpose in
                            Button { trip.purpose = purpose } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: purpose.icon).font(.system(size: 18))
                                        .foregroundColor(trip.purpose == purpose ? .white : Color(hex: "#FF6B35")!)
                                    Text(purpose.title).font(.system(size: 11, weight: .medium))
                                        .foregroundColor(trip.purpose == purpose ? .white : .white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(trip.purpose == purpose ? Color(hex: "#FF6B35")! : Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }.padding(16)
        }
    }
}

// MARK: - Step 1: Object Select

struct ObjectSelectStep: View {
    @Bindable var trip: FieldTrip
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Выберите тип устанавливаемой конструкции")
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center).padding(.top, 8)
                ForEach(AMOObject.sampleData) { obj in
                    Button { trip.selectedObject = obj } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(obj.color.opacity(0.12)).frame(width: 48, height: 48)
                                Text("AR").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(obj.color)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(obj.name).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                                Text("\(obj.type) · \(obj.height) · \(obj.weight)").font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            if trip.selectedObject?.id == obj.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(obj.color).font(.system(size: 22))
                            }
                        }
                        .padding(14)
                        .background(trip.selectedObject?.id == obj.id ? obj.color.opacity(0.08) : Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(trip.selectedObject?.id == obj.id ? obj.color.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5))
                    }
                }
            }.padding(16)
        }
    }
}

// MARK: - Step 2: Summary

struct TripSummaryStep: View {
    @Bindable var trip: FieldTrip
    let settings: AppSettings
    var locationManager: LocationManager
    @Binding var showAR: Bool
    @Binding var showReport: Bool
    @State private var selectedGeoPhoto: GeoPhoto?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GPSStatusCard(trip: trip, locationManager: locationManager)

                SummaryCard(title: "САЙТ") {
                    SummaryRow(label: "ID", value: trip.siteID)
                    SummaryRow(label: "Название", value: trip.siteName)
                    SummaryRow(label: "Регион", value: trip.region)
                    SummaryRow(label: "Адрес", value: trip.address)
                    SummaryRow(label: "Цель", value: trip.purpose.title)
                }

                if let obj = trip.selectedObject {
                    SummaryCard(title: "ОБЪЕКТ АМС") {
                        SummaryRow(label: "Тип", value: obj.name)
                        SummaryRow(label: "Высота", value: obj.height)
                        SummaryRow(label: "Масса", value: obj.weight)
                        SummaryRow(label: "База", value: obj.base)
                    }
                }

                if !trip.geoPhotos.isEmpty {
                    GeoPhotoStrip(geoPhotos: trip.geoPhotos, selectedPhoto: $selectedGeoPhoto)
                }

                if trip.geoPhotos.contains(where: { $0.hasLocation }) {
                    PhotoMapView(
                        geoPhotos: trip.geoPhotos,
                        tripLocation: trip.latitude != nil ? CLLocationCoordinate2D(latitude: trip.latitude!, longitude: trip.longitude!) : nil
                    )
                }

                Button { showAR = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(hex: "#00B4D8")!.opacity(0.2)).frame(width: 44, height: 44)
                            Image(systemName: "arkit").font(.system(size: 20)).foregroundColor(Color(hex: "#00B4D8")!)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Открыть AR").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            Text(trip.geoPhotos.isEmpty ? "Сделайте фото мачты на месте" : "Добавить ещё фото  (\(trip.geoPhotos.count) шт.)")
                                .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        if !trip.geoPhotos.isEmpty { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14).background(Color(hex: "#00B4D8")!.opacity(0.1)).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#00B4D8")!.opacity(0.4), lineWidth: 1))
                }
                .disabled(trip.selectedObject == nil)

                Button { showReport = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(hex: "#FF6B35")!.opacity(0.2)).frame(width: 44, height: 44)
                            Image(systemName: "doc.richtext.fill").font(.system(size: 20)).foregroundColor(Color(hex: "#FF6B35")!)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Сформировать акт").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            Text(trip.geoPhotos.isEmpty ? "PDF · A4 · без фото" : "PDF · A4 · с AR-фото + GPS ✓")
                                .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14).background(Color(hex: "#FF6B35")!).cornerRadius(14)
                    .shadow(color: Color(hex: "#FF6B35")!.opacity(0.4), radius: 10, y: 4)
                }
                .disabled(!trip.isReadyForReport)
            }
            .padding(16)
        }
        .sheet(item: $selectedGeoPhoto) { photo in GeoPhotoDetailView(photo: photo) }
    }
}

// MARK: - GPS Status Card

struct GPSStatusCard: View {
    @Bindable var trip: FieldTrip
    var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(locationManager.isAuthorized ?
                              (locationManager.location != nil ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                              : Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: locationManager.isAuthorized ?
                          (locationManager.location != nil ? "location.fill" : "location.slash")
                          : "location.slash.fill")
                        .foregroundColor(locationManager.isAuthorized ?
                                         (locationManager.location != nil ? .green : .orange) : .red)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(locationManager.isAuthorized ?
                         (locationManager.location != nil ? "GPS активен" : "Поиск спутников...")
                         : "GPS не разрешён")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    if locationManager.location != nil {
                        Text(trip.latString + "  " + trip.lonString)
                            .font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                    } else if !locationManager.isAuthorized {
                        Text("Настройки → Конфиденциальность → GefestAR")
                            .font(.system(size: 10)).foregroundColor(.orange)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    if locationManager.location != nil {
                        Text(trip.accuracyString)
                            .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.green)
                        Text(trip.altitudeString)
                            .font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                    } else if !locationManager.isAuthorized {
                        Button("Настройки") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "#FF6B35")!)
                    }
                }
            }
            if !trip.addressResolved.isEmpty && trip.addressResolved != "Определение адреса..." {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(Color(hex: "#FF6B35")!).font(.system(size: 12))
                    Text(trip.addressResolved).font(.system(size: 11)).foregroundColor(.white.opacity(0.6)).lineLimit(2)
                    Spacer()
                    if let url = trip.mapsURL {
                        Link(destination: url) {
                            HStack(spacing: 3) {
                                Image(systemName: "map").font(.system(size: 10))
                                Text("Карта").font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#00B4D8")!)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color(hex: "#00B4D8")!.opacity(0.1)).cornerRadius(8)
                        }
                    }
                }.padding(.horizontal, 4)
            }
        }
        .padding(14).background(Color.white.opacity(0.04)).cornerRadius(14)
    }
}

// MARK: - GeoPhoto Strip

struct GeoPhotoStrip: View {
    let geoPhotos: [GeoPhoto]
    @Binding var selectedPhoto: GeoPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ФОТО ИЗ AR (\(geoPhotos.count) шт.)")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.35))
                Spacer()
                Text("Нажмите → карта").font(.system(size: 10)).foregroundColor(.white.opacity(0.25))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(geoPhotos.enumerated()), id: \.element.id) { i, photo in
                        Button { selectedPhoto = photo } label: {
                            ZStack(alignment: .bottom) {
                                Image(uiImage: photo.image)
                                    .resizable().scaledToFill()
                                    .frame(width: 110, height: 82).clipped().cornerRadius(10)
                                HStack(spacing: 3) {
                                    Image(systemName: photo.hasLocation ? "location.fill" : "location.slash").font(.system(size: 8))
                                    Text(photo.hasLocation ? photo.coordString : "Нет GPS")
                                        .font(.system(size: 7, design: .monospaced)).lineLimit(1)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.black.opacity(0.65)).cornerRadius(5)
                                .padding(.bottom, 4).padding(.horizontal, 4)
                                if i == 0 {
                                    VStack {
                                        HStack {
                                            Text("В АКТ").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                                                .padding(.horizontal, 5).padding(.vertical, 2)
                                                .background(Color(hex: "#FF6B35")!).cornerRadius(4).padding(4)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12).background(Color.white.opacity(0.04)).cornerRadius(14)
    }
}

// MARK: - Photo Map View

struct PhotoMapView: View {
    let geoPhotos: [GeoPhoto]
    let tripLocation: CLLocationCoordinate2D?
    @State private var selectedPhoto: GeoPhoto?

    var region: MKCoordinateRegion {
        let coords = geoPhotos.compactMap { $0.coordinate }
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: tripLocation ?? CLLocationCoordinate2D(latitude: 42.87, longitude: 74.59),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2, longitude: (lons.min()! + lons.max()!) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((lats.max()! - lats.min()!) * 2, 0.002), longitudeDelta: max((lons.max()! - lons.min()!) * 2, 0.002))
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("КАРТА ТОЧЕК СЪЁМКИ").font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.35))
            Map(initialPosition: .region(region)) {
                ForEach(geoPhotos.filter { $0.hasLocation }) { photo in
                    Annotation("", coordinate: photo.coordinate!) {
                        Button { selectedPhoto = photo } label: {
                            ZStack {
                                Circle().fill(Color(hex: "#FF6B35")!).frame(width: 36, height: 36).shadow(color: .black.opacity(0.3), radius: 4)
                                Image(uiImage: photo.image).resizable().scaledToFill().frame(width: 30, height: 30).clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .frame(height: 200).cornerRadius(12)
            Text("Нажмите на маркер для просмотра").font(.system(size: 10)).foregroundColor(.white.opacity(0.25))
        }
        .padding(12).background(Color.white.opacity(0.04)).cornerRadius(14)
        .sheet(item: $selectedPhoto) { photo in GeoPhotoDetailView(photo: photo) }
    }
}

// MARK: - GeoPhoto Detail View

struct GeoPhotoDetailView: View {
    let photo: GeoPhoto
    @Environment(\.dismiss) var dismiss
    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Image(uiImage: photo.image).resizable().scaledToFit().cornerRadius(12).padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("GPS ДАННЫЕ").font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.35)).padding(.bottom, 8)
                            geoRow(icon: "location.fill", label: "Широта", value: photo.latString, color: Color(hex: "#00B4D8")!)
                            geoRow(icon: "location.fill", label: "Долгота", value: photo.lonString, color: Color(hex: "#00B4D8")!)
                            if let acc = photo.accuracy { geoRow(icon: "scope", label: "Точность", value: String(format: "±%.0f м", acc), color: .green) }
                            if let alt = photo.altitude { geoRow(icon: "mountain.2", label: "Высота н.у.м.", value: String(format: "%.0f м", alt), color: Color(hex: "#F59E0B")!) }
                            geoRow(icon: "clock", label: "Время съёмки", value: photo.timeString, color: .gray)
                        }
                        .padding(16).background(Color(red: 0.06, green: 0.10, blue: 0.16)).cornerRadius(14).padding(.horizontal, 16)

                        if photo.hasLocation {
                            VStack(spacing: 10) {
                                Text("ОТКРЫТЬ В КАРТАХ").font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.35)).frame(maxWidth: .infinity, alignment: .leading)
                                HStack(spacing: 10) {
                                    if let url = photo.mapsURL { mapButton("Apple Maps", icon: "map.fill", color: Color(hex: "#00B4D8")!, url: url) }
                                    if let url = photo.yandexMapsURL { mapButton("Яндекс", icon: "car.fill", color: Color(hex: "#FFB703")!, url: url) }
                                    if let url = photo.googleMapsURL { mapButton("Google", icon: "globe", color: .green, url: url) }
                                }
                            }.padding(.horizontal, 16)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("КООРДИНАТЫ (WGS-84)").font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.35))
                                Text(photo.coordString).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(.white)
                            }
                            Spacer()
                            Button { UIPasteboard.general.string = photo.coordString } label: {
                                Image(systemName: "doc.on.doc").foregroundColor(Color(hex: "#FF6B35")!).font(.system(size: 18))
                            }
                        }
                        .padding(14).background(Color(red: 0.06, green: 0.10, blue: 0.16)).cornerRadius(12).padding(.horizontal, 16)
                    }
                    .padding(.top, 16).padding(.bottom, 40)
                }
            }
            .navigationTitle("Фото · \(photo.timeString)").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Закрыть") { dismiss() }.foregroundColor(Color(hex: "#FF6B35")!) } }
        }
        .preferredColorScheme(.dark)
    }

    func geoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 14)).frame(width: 20)
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(.white)
        }
        .padding(.vertical, 8).overlay(alignment: .bottom) { Divider().opacity(0.08) }
    }

    func mapButton(_ title: String, icon: String, color: Color, url: URL) -> some View {
        Link(destination: url) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).frame(height: 64)
            .background(color.opacity(0.1)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

// MARK: - AR View With Trip

struct ARViewScreenWithTrip: View {
    let object: AMOObject
    @Bindable var trip: FieldTrip
    var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss
    @State private var arCoordinator = ARCoordinator()

    @State private var showDimensions = false
    @State private var showSpecs = false
    @State private var isRecording = false
    @State private var notification: String?
    @State private var hasPlacedObject = false

    var body: some View {
        ZStack {
            ARSceneView(object: object, coordinator: arCoordinator).ignoresSafeArea()
            if arCoordinator.surfaceState == .scanning { ScanningOverlay() }
            if arCoordinator.surfaceState == .ready { CrosshairView(color: object.color) }
            if showDimensions && arCoordinator.isObjectPlaced { DimensionsOverlay(object: object, color: object.color) }
            if showSpecs && arCoordinator.isObjectPlaced { SpecsOverlay(object: object) }
            if let msg = notification { NotificationToast(message: msg) }
            if isRecording { RecordingIndicator() }

            if !trip.geoPhotos.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill").font(.system(size: 11))
                            Text("\(trip.geoPhotos.count) фото").font(.system(size: 12, weight: .bold))
                            if trip.geoPhotos.first?.hasLocation == true {
                                Image(systemName: "location.fill").font(.system(size: 10)).foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(hex: "#FF6B35")!.opacity(0.9)).cornerRadius(14)
                        .padding(.trailing, 16).padding(.top, 54)
                    }
                    Spacer()
                }
            }
            topBar
            VStack { Spacer(); bottomControls }
        }
        .statusBarHidden(true)
        .onChange(of: arCoordinator.isObjectPlaced) { _, placed in
            if placed { hasPlacedObject = true }
        }
    }

    var topBar: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Назад") }
                        .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8).background(.ultraThinMaterial).cornerRadius(20)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(locationManager.location != nil ? Color.green : Color.orange).frame(width: 6, height: 6)
                    Text(locationManager.location != nil ? locationManager.accuracyString : "GPS...")
                        .font(.system(size: 10, design: .monospaced)).foregroundColor(.white)
                }
                .padding(.horizontal, 8).padding(.vertical, 4).background(.ultraThinMaterial).cornerRadius(10)
                Spacer()
                Text(object.name).font(.system(size: 12, weight: .semibold)).foregroundColor(object.color)
                    .padding(.horizontal, 10).padding(.vertical, 5).background(.ultraThinMaterial).cornerRadius(10)
            }
            .padding(.horizontal, 16).padding(.top, 54)
            Spacer()
        }
    }

    var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ControlButton(icon: "ruler", label: "Размеры", isActive: showDimensions, color: object.color) {
                    withAnimation { showDimensions.toggle() }
                }.disabled(!arCoordinator.isObjectPlaced)
                ControlButton(icon: "info.circle", label: "ТТХ", isActive: showSpecs, color: object.color) {
                    withAnimation { showSpecs.toggle() }
                }.disabled(!arCoordinator.isObjectPlaced)
            }
            HStack(spacing: 44) {
                GalleryThumbnailButton()
                ShutterButton(isRecording: isRecording) { isLong in
                    if isLong { toggleRecording() } else { takePhoto() }
                }
                FlashlightButton()
            }
        }
        .padding(.horizontal, 28).padding(.bottom, 40).padding(.top, 16)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
    }

    func takePhoto() {
        let currentLocation = locationManager.location
        arCoordinator.capturePhoto { image in
            guard let image else { return }
            trip.addARPhoto(image, location: currentLocation)
            savePhotoToLibrary(image)
            let gpsText = currentLocation != nil ? " · GPS ✓" : " · GPS нет"
            showNotification("📷 Фото \(trip.geoPhotos.count)\(gpsText) · В акте")
        }
    }

    func toggleRecording() {
        if isRecording {
            arCoordinator.stopVideoRecording { url in
                guard let url else { return }
                saveVideoToLibrary(url)
                showNotification("✅ Видео сохранено")
            }
            isRecording = false
        } else {
            arCoordinator.startVideoRecording()
            isRecording = true
            showNotification("🔴 Запись...")
        }
    }

    func savePhotoToLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAsset(from: image) }
        }
    }

    func saveVideoToLibrary(_ url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }
        }
    }

    func showNotification(_ message: String) {
        notification = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { notification = nil }
    }
}

// MARK: - Shared Components

struct FormCard<Content: View>: View {
    let title: String; @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.35))
            VStack(spacing: 10) { content }.padding(14).background(Color.white.opacity(0.04)).cornerRadius(14)
        }
    }
}

struct TripField: View {
    let label: String; let placeholder: String; @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.3))
            TextField(placeholder, text: $text).foregroundColor(.white).autocorrectionDisabled()
                .padding(10).background(Color.white.opacity(0.06)).cornerRadius(9)
        }
    }
}

struct SummaryCard<Content: View>: View {
    let title: String; @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.35))
            VStack(spacing: 0) { content }.background(Color.white.opacity(0.04)).cornerRadius(12)
        }
    }
}

struct SummaryRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value.isEmpty ? "—" : value).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider().opacity(0.08) }
    }
}

