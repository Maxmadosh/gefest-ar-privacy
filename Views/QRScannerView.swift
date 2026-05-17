import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins
import Observation

// MARK: - QR Scanner Screen

struct QRScannerScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var scanner = QRScannerCoordinator()
    @State private var scannedObject: AMOObject?
    @State private var showAR = false
    @State private var errorMessage: String?
    @State private var scanSuccess = false

    var body: some View {
        ZStack {
            QRCameraView(coordinator: scanner).ignoresSafeArea()
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Назад") }
                            .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8).background(.ultraThinMaterial).cornerRadius(20)
                    }
                    Spacer()
                    Text("Сканер QR").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(.ultraThinMaterial).cornerRadius(10)
                    Spacer()
                    Color.clear.frame(width: 80)
                }
                .padding(.horizontal, 16).padding(.top, 54)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scanSuccess ? Color.green : Color(hex: "#FF6B35")!, lineWidth: 3)
                        .frame(width: 240, height: 240)
                    if !scanSuccess { ScanLine() }
                    else { Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(.green) }
                }
                Text(scanSuccess ? "Объект найден!" : "Наведите на QR-код объекта")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(.ultraThinMaterial).cornerRadius(20)
                    .padding(.top, 24)
                if let error = errorMessage {
                    Text(error).font(.system(size: 13)).foregroundColor(.red).padding(.top, 8)
                }
                Spacer()
                if let obj = scannedObject {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(obj.color).font(.system(size: 20))
                                .frame(width: 48, height: 48).background(obj.color.opacity(0.15)).cornerRadius(10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(obj.name).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                Text(obj.type).font(.system(size: 12)).foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                        }.padding(.horizontal, 20)
                        Button { showAR = true } label: {
                            HStack(spacing: 8) { Image(systemName: "arkit").font(.system(size: 18)); Text("Открыть в AR").fontWeight(.semibold) }
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 54)
                                .background(LinearGradient(colors: [obj.color, obj.color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(14).padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20).background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal, 16)
                }
                Spacer(minLength: 40)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: scanner.scannedCode) { _, code in
            guard let code else { return }
            processQRCode(code)
        }
        .fullScreenCover(isPresented: $showAR) {
            if let obj = scannedObject { ARViewScreen(object: obj) }
        }
    }

    func processQRCode(_ code: String) {
        guard code.hasPrefix("gefest://object/") else {
            errorMessage = "Неверный QR-код GefestAR."; return
        }
        let id = code.replacingOccurrences(of: "gefest://object/", with: "")
        if let obj = AMOObject.sampleData.first(where: { $0.id == id }) {
            scannedObject = obj; scanSuccess = true; errorMessage = nil; scanner.stop()
        } else {
            errorMessage = "Объект '\(id)' не найден."
        }
    }
}

// MARK: - Camera View

struct QRCameraView: UIViewRepresentable {
    var coordinator: QRScannerCoordinator
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero); view.backgroundColor = .black
        let preview = AVCaptureVideoPreviewLayer(session: coordinator.session)
        preview.videoGravity = .resizeAspectFill; view.layer.addSublayer(preview)
        coordinator.previewLayer = preview; coordinator.start(); return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        coordinator.previewLayer?.frame = uiView.bounds
    }
}

// MARK: - QR Coordinator

@Observable
class QRScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var scannedCode: String?
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { session.commitConfiguration(); return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        isRunning = true
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
        isRunning = false
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue else { return }
        scannedCode = code
    }
}

// MARK: - QR Generator Screen

struct QRGeneratorScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedObject = AMOObject.sampleData[0]
    @State private var showShareSheet = false
    let bg = Color(red: 0.02, green: 0.05, blue: 0.09)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AMOObject.sampleData) { obj in
                                    Button { selectedObject = obj } label: {
                                        Text(obj.name).font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedObject.id == obj.id ? .white : obj.color)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(selectedObject.id == obj.id ? obj.color : obj.color.opacity(0.1)).cornerRadius(20)
                                    }
                                }
                            }.padding(.horizontal, 20)
                        }
                        VStack(spacing: 16) {
                            if let qr = generateQR(for: selectedObject) {
                                Image(uiImage: qr).interpolation(.none).resizable().scaledToFit()
                                    .frame(width: 200, height: 200).padding(20).background(.white).cornerRadius(16)
                            }
                            Text(selectedObject.name).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            Text(selectedObject.type).font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                            Text("gefest://object/\(selectedObject.id)").font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.3))
                            HStack(spacing: 20) {
                                QRSpecTag(label: "H", value: selectedObject.height, color: selectedObject.color)
                                QRSpecTag(label: "M", value: selectedObject.weight, color: selectedObject.color)
                                QRSpecTag(label: "P", value: selectedObject.payload, color: selectedObject.color)
                            }
                        }
                        .padding(24).background(Color(red: 0.06, green: 0.10, blue: 0.16)).cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedObject.color.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal, 20)
                        VStack(spacing: 12) {
                            Button {
                                if let qr = generateQR(for: selectedObject) { UIImageWriteToSavedPhotosAlbum(qr, nil, nil, nil) }
                            } label: {
                                HStack(spacing: 8) { Image(systemName: "square.and.arrow.down"); Text("Сохранить в галерею").fontWeight(.semibold) }
                                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 52).background(selectedObject.color).cornerRadius(14)
                            }
                            Button { showShareSheet = true } label: {
                                HStack(spacing: 8) { Image(systemName: "square.and.arrow.up"); Text("Поделиться QR").fontWeight(.semibold) }
                                    .foregroundColor(selectedObject.color).frame(maxWidth: .infinity).frame(height: 52)
                                    .background(selectedObject.color.opacity(0.1)).cornerRadius(14)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedObject.color.opacity(0.5), lineWidth: 1))
                            }
                        }.padding(.horizontal, 20)
                    }.padding(.top, 16).padding(.bottom, 40)
                }
            }
            .navigationTitle("QR-коды").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() }.foregroundColor(Color(hex: "#FF6B35")!) } }
            .sheet(isPresented: $showShareSheet) {
                if let qr = generateQR(for: selectedObject) { ShareSheet(items: [qr]) }
            }
        }
        .preferredColorScheme(.dark)
    }

    func generateQR(for object: AMOObject) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data("gefest://object/\(object.id)".utf8)
        filter.correctionLevel = "H"
        guard let ci = filter.outputImage else { return nil }
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct ScanLine: View {
    @State private var offset: CGFloat = -100
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, Color(hex: "#FF6B35")!.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(width: 200, height: 2).offset(y: offset)
            .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { offset = 100 } }
    }
}

struct QRSpecTag: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(color)
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundColor(.white).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 10).padding(.vertical, 6).background(color.opacity(0.1)).cornerRadius(8)
    }
}
