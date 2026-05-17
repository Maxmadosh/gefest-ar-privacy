import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import Observation

// MARK: - Distance Measurement View

struct DistanceMeasurementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var coordinator = DistanceMeasureCoordinator()

    var body: some View {
        ZStack {
            DistanceARView(coordinator: coordinator).ignoresSafeArea()
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Назад") }
                            .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8).background(.ultraThinMaterial).cornerRadius(20)
                    }
                    Spacer()
                    Text("ИЗМЕРЕНИЕ").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(.ultraThinMaterial).cornerRadius(10)
                    Spacer()
                    Button { coordinator.reset() } label: {
                        Image(systemName: "arrow.counterclockwise").foregroundColor(.white)
                            .frame(width: 36, height: 36).background(.ultraThinMaterial).cornerRadius(18)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 54)
                Spacer()
                ZStack {
                    Circle().stroke(Color.white.opacity(0.5), lineWidth: 1).frame(width: 20, height: 20)
                    Circle().fill(coordinator.pointsPlaced == 0 ? Color.white : Color(hex: "#00B4D8")!).frame(width: 6, height: 6)
                }
                Spacer()
                VStack(spacing: 12) {
                    if coordinator.distance > 0 {
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("РАССТОЯНИЕ").font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                                Text(coordinator.distanceString).font(.system(size: 32, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "#00B4D8")!)
                            }.frame(maxWidth: .infinity)
                            Divider().frame(height: 40)
                            VStack(spacing: 4) {
                                Text("ТОЧКИ").font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                                Text("\(coordinator.pointsPlaced)/2").font(.system(size: 32, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            }.frame(maxWidth: .infinity)
                        }
                        .padding(20).background(.ultraThinMaterial).cornerRadius(16).padding(.horizontal, 16)
                    }
                    Text(coordinator.hint).font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10).background(.ultraThinMaterial).cornerRadius(20)
                    if coordinator.pointsPlaced < 2 {
                        Button { coordinator.addPoint() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Поставить точку \(coordinator.pointsPlaced + 1)").fontWeight(.semibold)
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color(hex: "#00B4D8")!).cornerRadius(14).padding(.horizontal, 16)
                        }
                    }
                }.padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true).statusBarHidden(true)
    }
}

struct DistanceARView: UIViewRepresentable {
    var coordinator: DistanceMeasureCoordinator
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        coordinator.arView = arView
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

@Observable
class DistanceMeasureCoordinator {
    var arView: ARView?
    var distance: Float = 0
    var pointsPlaced: Int = 0
    private var point1: SIMD3<Float>?
    private var point2: SIMD3<Float>?
    private var anchors: [AnchorEntity] = []

    var distanceString: String {
        distance < 1 ? String(format: "%.0f см", distance * 100) : String(format: "%.2f м", distance)
    }
    var hint: String {
        switch pointsPlaced {
        case 0: return "Наведите прицел на первую точку"
        case 1: return "Наведите прицел на вторую точку"
        default: return "Готово! Нажмите ↺ для нового"
        }
    }

    func addPoint() {
        guard let arView else { return }
        let results = arView.raycast(from: CGPoint(x: arView.bounds.midX, y: arView.bounds.midY),
                                     allowing: .estimatedPlane, alignment: .any)
        guard let r = results.first else { return }
        let c = r.worldTransform.columns.3
        let pos = SIMD3<Float>(c.x, c.y, c.z)
        let sphere = MeshResource.generateSphere(radius: 0.02)
        let mat = SimpleMaterial(color: pointsPlaced == 0 ? .systemGreen : .systemBlue, isMetallic: false)
        let entity = ModelEntity(mesh: sphere, materials: [mat])
        let anchor = AnchorEntity(world: r.worldTransform)
        anchor.addChild(entity); arView.scene.addAnchor(anchor); anchors.append(anchor)
        if pointsPlaced == 0 { point1 = pos; pointsPlaced = 1 }
        else { point2 = pos; pointsPlaced = 2; calcDistance(); drawLine() }
    }

    func calcDistance() {
        guard let p1 = point1, let p2 = point2 else { return }
        let d = p2 - p1; distance = sqrt(d.x*d.x + d.y*d.y + d.z*d.z)
    }

    func drawLine() {
        guard let p1 = point1, let p2 = point2, let arView else { return }
        let mid = (p1 + p2) / 2
        let box = MeshResource.generateBox(size: [0.005, 0.005, distance])
        let mat = SimpleMaterial(color: .systemCyan.withAlphaComponent(0.8), isMetallic: false)
        let line = ModelEntity(mesh: box, materials: [mat])
        line.transform.rotation = simd_quatf(from: [0,0,1], to: normalize(p2 - p1))
        var t = matrix_identity_float4x4
        t.columns.3 = SIMD4<Float>(mid.x, mid.y, mid.z, 1)
        let anchor = AnchorEntity(world: t); anchor.addChild(line)
        arView.scene.addAnchor(anchor); anchors.append(anchor)
    }

    func reset() {
        anchors.forEach { arView?.scene.removeAnchor($0) }
        anchors.removeAll(); point1 = nil; point2 = nil; distance = 0; pointsPlaced = 0
    }
}

// MARK: - Offline Cache Manager

@Observable
class OfflineCacheManager {
    static let shared = OfflineCacheManager()
    private let cacheDir: URL
    var cachedObjectIDs: Set<String> = []
    var totalCacheSize: String = "0 МБ"
    var isDownloading = false
    var downloadProgress: Double = 0

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDir = docs.appendingPathComponent("GefestARCache")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        loadCachedObjects()
    }

    func loadCachedObjects() {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir.path)) ?? []
        cachedObjectIDs = Set(files.compactMap { $0.hasSuffix(".usdz") ? String($0.dropLast(5)) : nil })
        updateCacheSize()
    }

    func isCached(_ id: String) -> Bool { cachedObjectIDs.contains(id) }
    func cacheURL(for id: String) -> URL { cacheDir.appendingPathComponent("\(id).usdz") }

    func downloadForOffline(object: AMOObject) {
        guard !isCached(object.id) else { return }
        isDownloading = true
        let dest = cacheURL(for: object.id)
        let id = object.id; let fileName = object.usdzFileName
        Task { @MainActor in
            if let url = Bundle.main.url(forResource: fileName, withExtension: "usdz") {
                try? FileManager.default.copyItem(at: url, to: dest)
            }
            self.cachedObjectIDs.insert(id); self.isDownloading = false; self.updateCacheSize()
        }
    }

    func downloadAll() {
        isDownloading = true; downloadProgress = 0
        let objects = AMOObject.sampleData; let total = Double(objects.count)
        Task { @MainActor in
            for (i, obj) in objects.enumerated() {
                if let url = Bundle.main.url(forResource: obj.usdzFileName, withExtension: "usdz") {
                    try? FileManager.default.copyItem(at: url, to: self.cacheURL(for: obj.id))
                }
                self.cachedObjectIDs.insert(obj.id)
                self.downloadProgress = Double(i + 1) / total
            }
            self.isDownloading = false; self.updateCacheSize()
        }
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        cachedObjectIDs.removeAll(); updateCacheSize()
    }

    private func updateCacheSize() {
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let bytes = files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) }
        totalCacheSize = String(format: "%.1f МБ", Double(bytes) / 1_048_576)
    }
}

// MARK: - Offline Settings View

struct OfflineSettingsView: View {
    @State private var cache = OfflineCacheManager.shared
    @Environment(\.dismiss) var dismiss
    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Офлайн кеш").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                Text("Размер: \(cache.totalCacheSize)").font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            Image(systemName: cache.cachedObjectIDs.isEmpty ? "wifi.slash" : "checkmark.icloud.fill")
                                .foregroundColor(cache.cachedObjectIDs.isEmpty ? .red : .green).font(.system(size: 28))
                        }
                        .padding(16).background(Color(red: 0.06, green: 0.10, blue: 0.16)).cornerRadius(14)

                        if cache.isDownloading {
                            ProgressView(value: cache.downloadProgress).tint(Color(hex: "#00B4D8")!)
                        }
                        Button { cache.downloadAll() } label: {
                            HStack(spacing: 8) { Image(systemName: "arrow.down.circle.fill"); Text("Скачать все объекты").fontWeight(.semibold) }
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 52).background(Color(hex: "#00B4D8")!).cornerRadius(14)
                        }.disabled(cache.isDownloading)
                        Button { cache.clearCache() } label: {
                            HStack(spacing: 8) { Image(systemName: "trash"); Text("Очистить кеш").fontWeight(.semibold) }
                                .foregroundColor(.red).frame(maxWidth: .infinity).frame(height: 52)
                                .background(Color.red.opacity(0.1)).cornerRadius(14)
                        }
                        ForEach(AMOObject.sampleData) { obj in
                            HStack(spacing: 12) {
                                Text("AR").font(.system(size: 10, weight: .bold)).foregroundColor(obj.color)
                                    .frame(width: 36, height: 36).background(obj.color.opacity(0.12)).cornerRadius(8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(obj.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    Text(obj.type).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                if cache.isCached(obj.id) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                } else {
                                    Button { cache.downloadForOffline(object: obj) } label: {
                                        Image(systemName: "arrow.down.circle").foregroundColor(Color(hex: "#00B4D8")!).font(.system(size: 20))
                                    }
                                }
                            }
                            .padding(12).background(Color(red: 0.04, green: 0.08, blue: 0.13)).cornerRadius(12)
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Офлайн режим").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() }.foregroundColor(Color(hex: "#FF6B35")!) } }
        }
        .preferredColorScheme(.dark)
    }
}
