import RealityKit
import ARKit
import UIKit
import Observation

@Observable
class ARCoordinator: NSObject, ARSessionDelegate {
    var arView: ARView?
    var objectFileName: String = ""
    var surfaceState: SurfaceState = .scanning
    var isObjectPlaced: Bool = false
    var isFixed: Bool = false

    enum SurfaceState { case scanning, ready, placed }

    private var mainAnchor: AnchorEntity?
    private var modelNode: Entity?
    private var recorder: ARVideoRecorder?

    // MARK: - Tap: размещение

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView, !isFixed else { return }
        guard let frame = arView.session.currentFrame,
              case .normal = frame.camera.trackingState else { return }

        let point = gesture.location(in: arView)

        // Ищем реальную плоскость
        let hits = arView.raycast(from: point,
                                   allowing: .existingPlaneGeometry,
                                   alignment: .horizontal)
        if let hit = hits.first {
            place(at: hit)
            return
        }
        // Fallback
        let estimated = arView.raycast(from: point,
                                        allowing: .estimatedPlane,
                                        alignment: .horizontal)
        if let hit = estimated.first { place(at: hit) }
    }

    private func place(at hit: ARRaycastResult) {
        guard let arView else { return }

        // Удаляем предыдущий
        if let old = mainAnchor { arView.scene.removeAnchor(old) }

        // КЛЮЧ: AnchorEntity(raycastResult:) — официальный Apple API
        // Объект привязывается к физической поверхности и НЕ следует за камерой
        let anchor = AnchorEntity(raycastResult: hit)
        let model = buildModel()
        anchor.addChild(model)
        arView.scene.addAnchor(anchor)
        mainAnchor = anchor
        modelNode = model

        DispatchQueue.main.async {
            self.isObjectPlaced = true
            self.surfaceState = .placed
        }
    }

    // MARK: - Pan: 2 ПАЛЬЦА для перемещения (чтобы не срабатывал случайно)

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isFixed, isObjectPlaced, gesture.numberOfTouches == 2 else { return }
        guard gesture.state == .changed else { return }
        guard let arView else { return }

        let translation = gesture.translation(in: arView)
        gesture.setTranslation(.zero, in: arView)

        guard let frame = arView.session.currentFrame else { return }
        let cam = frame.camera.transform
        let speed: Float = 0.003

        var right   = SIMD3<Float>(cam.columns.0.x, 0, cam.columns.0.z)
        var forward = SIMD3<Float>(-cam.columns.2.x, 0, -cam.columns.2.z)
        if simd_length(right)   > 0.001 { right   = simd_normalize(right) }
        if simd_length(forward) > 0.001 { forward = simd_normalize(forward) }

        let delta = right * Float(translation.x) * speed
                  + forward * (-Float(translation.y)) * speed

        modelNode?.position.x += delta.x
        modelNode?.position.z += delta.z
    }

    // MARK: - Pinch: масштаб

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let model = modelNode, gesture.state == .changed else { return }
        model.scale = model.scale * SIMD3<Float>(repeating: Float(gesture.scale))
        gesture.scale = 1
    }

    // MARK: - Rotation

    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let model = modelNode, gesture.state == .changed else { return }
        model.transform.rotation *= simd_quatf(angle: -Float(gesture.rotation), axis: [0, 1, 0])
        gesture.rotation = 0
    }

    // MARK: - Удалить

    func removeObject() {
        if let old = mainAnchor { arView?.scene.removeAnchor(old) }
        mainAnchor = nil; modelNode = nil
        DispatchQueue.main.async {
            self.isObjectPlaced = false
            self.surfaceState = .ready
            self.isFixed = false
        }
    }

    // MARK: - Загрузка модели

    private func buildModel() -> Entity {
        // Из Bundle
        if let m = try? ModelEntity.load(named: objectFileName) { return m }
        // Из Documents
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(objectFileName + ".usdz")
        if let m = try? ModelEntity.load(contentsOf: url) { return m }
        // Плейсхолдер
        return makePlaceholder()
    }

    private func makePlaceholder() -> Entity {
        let root = Entity()
        let body = ModelEntity(mesh: .generateBox(size:[0.15,2.0,0.15]),
                               materials:[SimpleMaterial(color:.systemOrange, isMetallic:false)])
        body.position.y = 1.0
        let base = ModelEntity(mesh: .generateBox(size:[0.6,0.04,0.6]),
                               materials:[SimpleMaterial(color:.systemGray2, isMetallic:false)])
        base.position.y = 0.02
        root.addChild(body); root.addChild(base)
        return root
    }

    // MARK: - Фото / Видео

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let arView else { completion(nil); return }
        completion(UIGraphicsImageRenderer(bounds:arView.bounds).image { _ in
            arView.drawHierarchy(in:arView.bounds, afterScreenUpdates:true)
        })
    }

    func startVideoRecording() {
        guard let arView else { return }
        recorder = ARVideoRecorder(arView:arView); recorder?.start()
    }

    func stopVideoRecording(completion: @escaping (URL?)->Void) {
        recorder?.stop(completion:completion); recorder = nil
    }

    // MARK: - Session delegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if anchors.contains(where: { $0 is ARPlaneAnchor }) && surfaceState == .scanning {
            DispatchQueue.main.async { self.surfaceState = .ready }
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR: \(error.localizedDescription)")
    }
    // MARK: - UIGestureRecognizerDelegate
    extension ARCoordinator: UIGestureRecognizerDelegate {
        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }
    }
    }
