import SwiftUI
import RealityKit
import ARKit
import AVFoundation
import Photos
import CoreLocation
import Observation

// MARK: - AR View Screen

struct ARViewScreen: View {
    let object: AMOObject
    @Environment(\.dismiss) var dismiss
    @Environment(AppSettings.self) var settings
    @State private var arCoordinator = ARCoordinator()
    @State private var locationManager = LocationManager()

    @State private var siteID: String = ""
    @State private var siteName: String = ""
    @State private var showSiteForm = true
    @State private var photos: [ReportPhoto] = []
    @State private var showReport = false
    @State private var showDimensions = false
    @State private var showSpecs = false
    @State private var isRecording = false
    @State private var notification: String?
    @State private var hasPlacedObject = false
    @State private var isFixed = false

    @State private var mastLatitude: Double? = nil
    @State private var mastLongitude: Double? = nil
    @State private var mastAccuracy: Double? = nil

    var body: some View {
        ZStack {
            ARSceneView(object: object, coordinator: arCoordinator).ignoresSafeArea()

            if arCoordinator.surfaceState == .scanning { ScanningOverlay() }
            if arCoordinator.surfaceState == .ready && !hasPlacedObject { CrosshairView(color: object.color) }
            if showDimensions && arCoordinator.isObjectPlaced { DimensionsOverlay(object: object, color: object.color) }
            if showSpecs && arCoordinator.isObjectPlaced { SpecsOverlay(object: object) }
            if let msg = notification { NotificationToast(message: msg) }
            if isRecording { RecordingIndicator() }

            // Статус + GPS мачты вверху
            if hasPlacedObject {
                VStack {
                    HStack {
                        // GPS мачты
                        HStack(spacing: 6) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 10))
                                .foregroundColor(mastLatitude != nil ? Color(hex:"#FF6B35")! : .orange)
                            Text(mastLatitude != nil ?
                                String(format:"%.4f°, %.4f°", mastLatitude!, mastLongitude!) :
                                "GPS мачты не определён")
                                .font(.system(size: 9, design:.monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(.ultraThinMaterial).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius:8).stroke(Color(hex:"#FF6B35")!.opacity(0.3), lineWidth:1))
                        .padding(.leading, 16)

                        Spacer()

                        if !photos.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName:"photo.fill").font(.system(size:10))
                                Text("\(photos.count)").font(.system(size:12, weight:.bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal,10).padding(.vertical,6)
                            .background(Color(hex:"#FF6B35")!.opacity(0.9)).cornerRadius(12)
                            .padding(.trailing, 16)
                        }
                    }
                    .padding(.top, 54)
                    Spacer()
                }
            }

            // Подсказка — двигать пальцем
            if hasPlacedObject && !isFixed {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName:"hand.draw.fill")
                                .font(.system(size:20)).foregroundColor(.white.opacity(0.8))
                            Text("Двумя пальцами — переместить").font(.system(size:10)).foregroundColor(.white.opacity(0.6))
                            Text("Щипок — масштаб  |  🔓 — зафиксировать")
                                .font(.system(size:9)).foregroundColor(.orange.opacity(0.9))
                        }
                        .padding(10).background(.ultraThinMaterial).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius:12).stroke(Color.orange.opacity(0.3), lineWidth:1))
                        .padding(.trailing, 16).padding(.bottom, 220)
                    }
                }
            }

            topBar
            VStack { Spacer(); bottomControls }

            if showSiteForm {
                SiteFormOverlay(siteID: $siteID, siteName: $siteName) { showSiteForm = false }
            }
        }
        .statusBarHidden(true)
        .onChange(of: arCoordinator.isObjectPlaced) { _, placed in
            if placed {
                hasPlacedObject = true
                if let loc = locationManager.location {
                    mastLatitude = loc.coordinate.latitude
                    mastLongitude = loc.coordinate.longitude
                    mastAccuracy = loc.horizontalAccuracy
                    showNotification("📍 GPS мачты: \(String(format:"%.4f°, %.4f°", loc.coordinate.latitude, loc.coordinate.longitude))")
                } else {
                    showNotification("⚠️ GPS мачты не определён")
                }
            }
        }
        .sheet(isPresented: $showReport) {
            ReportView(
                initialSiteID: siteID,
                initialSiteName: siteName,
                initialPhotos: photos,
                initialLatitude: mastLatitude,
                initialLongitude: mastLongitude,
                initialAccuracy: mastAccuracy,
                initialAltitude: locationManager.location?.altitude
            )
        }
    }

    // MARK: - Top Bar

    var topBar: some View {
        VStack {
            HStack {
                Button {
                    if isRecording { stopRecording() }
                    dismiss()
                } label: {
                    HStack(spacing:6) { Image(systemName:"chevron.left"); Text("Назад") }
                        .font(.system(size:14, weight:.medium)).foregroundColor(.white)
                        .padding(.horizontal,14).padding(.vertical,8).background(.ultraThinMaterial).cornerRadius(20)
                }
                Spacer()
                VStack(spacing:2) {
                    Text(siteID.isEmpty ? object.name : siteID)
                        .font(.system(size:12, weight:.semibold, design:.monospaced))
                        .foregroundColor(object.color)
                    HStack(spacing:3) {
                        Circle().fill(locationManager.location != nil ? Color.green : Color.orange).frame(width:5, height:5)
                        Text(locationManager.location != nil ? locationManager.accuracyString : "GPS...")
                            .font(.system(size:9, design:.monospaced)).foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal,12).padding(.vertical,6).background(.ultraThinMaterial).cornerRadius(10)
                Spacer()
                if hasPlacedObject {
                    Button {
                        arCoordinator.removeObject()
                        hasPlacedObject = false
                        isFixed = false
                        mastLatitude = nil; mastLongitude = nil
                        showDimensions = false; showSpecs = false
                    } label: {
                        Image(systemName:"arrow.counterclockwise")
                            .font(.system(size:14)).foregroundColor(.white)
                            .frame(width:36, height:36).background(.ultraThinMaterial).cornerRadius(18)
                    }
                } else { Color.clear.frame(width:36, height:36) }
            }
            .padding(.horizontal,16).padding(.top,54)
            Spacer()
        }
    }

    // MARK: - Bottom Controls

    var bottomControls: some View {
        VStack(spacing:12) {
            HStack(spacing:12) {
                ControlButton(icon:"ruler", label:"Размеры", isActive:showDimensions, color:object.color) {
                    withAnimation { showDimensions.toggle() }
                }.disabled(!arCoordinator.isObjectPlaced)

                ControlButton(icon:"info.circle", label:"ТТХ", isActive:showSpecs, color:object.color) {
                    withAnimation { showSpecs.toggle() }
                }.disabled(!arCoordinator.isObjectPlaced)

                // Кнопка фиксации
                if hasPlacedObject {
                    Button {
                        withAnimation(.spring()) {
                            isFixed.toggle()
                            arCoordinator.isFixed = isFixed
                        }
                        showNotification(isFixed ? "🔒 Мачта зафиксирована" : "🔓 Мачта разблокирована")
                    } label: {
                        VStack(spacing:4) {
                            Image(systemName: isFixed ? "lock.fill" : "lock.open")
                                .font(.system(size:18))
                                .foregroundColor(isFixed ? .green : .orange)
                            Text(isFixed ? "Стоит" : "Свободна")
                                .font(.system(size:10))
                                .foregroundColor(isFixed ? .green : .orange)
                        }
                        .frame(width:64, height:54)
                        .background(.ultraThinMaterial).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius:12)
                            .stroke(isFixed ? Color.green.opacity(0.4) : Color.orange.opacity(0.4), lineWidth:1))
                    }
                }
            }

            HStack(spacing:44) {
                GalleryThumbnailButton()
                ShutterButton(isRecording:isRecording) { isLong in
                    if isLong { toggleRecording() } else { takePhoto() }
                }
                FlashlightButton()
            }

            Button { showReport = true } label: {
                HStack(spacing:12) {
                    Image(systemName:"doc.richtext.fill").font(.system(size:22))
                    VStack(alignment:.leading, spacing:2) {
                        Text("Оформить акт").font(.system(size:16, weight:.bold))
                        Text(photos.isEmpty ? "Сфотографируйте с разных сторон" : "\(photos.count) фото · GPS мачты сохранён")
                            .font(.system(size:11)).opacity(0.75)
                    }
                    Spacer()
                    Image(systemName:"chevron.right").font(.system(size:14))
                }
                .foregroundColor(.white)
                .padding(.horizontal,20).frame(height:56)
                .background(photos.isEmpty ? Color.white.opacity(0.12) : Color(hex:"#FF6B35")!)
                .cornerRadius(16)
                .shadow(color: photos.isEmpty ? .clear : Color(hex:"#FF6B35")!.opacity(0.5), radius:10, y:4)
            }
            .padding(.horizontal,16)
        }
        .padding(.horizontal,16).padding(.bottom,40).padding(.top,12)
        .background(LinearGradient(colors:[.clear, .black.opacity(0.85)], startPoint:.top, endPoint:.bottom))
    }

    // MARK: - Photo

    func takePhoto() {
        let location = locationManager.location
        arCoordinator.capturePhoto { image in
            guard let image else { return }
            let watermarked = addWatermark(to:image, location:location)
            photos.insert(ReportPhoto(image:watermarked, coordinate:location?.coordinate, altitude:location?.altitude, timestamp:Date()), at:0)
            saveToLibrary(watermarked)
            showNotification("📷 Фото \(photos.count)")
        }
    }

    func addWatermark(to image:UIImage, location:CLLocation?) -> UIImage {
        UIGraphicsImageRenderer(size:image.size).image { _ in
            image.draw(at:.zero)
            var parts:[String] = []
            if !siteID.isEmpty { parts.append(siteID) }
            if let lat = mastLatitude, let lon = mastLongitude {
                parts.append(String(format:"Мачта: %.5f°, %.5f°", lat, lon))
            }
            parts.append(DateFormatter.localizedString(from:Date(), dateStyle:.short, timeStyle:.short))
            if !settings.companyName.isEmpty { parts.append(settings.companyName) }
            let text = parts.joined(separator:"  |  ")
            let fontSize = image.size.width * 0.030
            let attrs:[NSAttributedString.Key:Any] = [
                .font: UIFont.boldSystemFont(ofSize:fontSize),
                .foregroundColor: UIColor.white,
                .backgroundColor: UIColor.black.withAlphaComponent(0.55)
            ]
            let sz = (text as NSString).size(withAttributes:attrs)
            let rect = CGRect(x:image.size.width*0.01, y:image.size.height*0.01, width:sz.width+10, height:sz.height+6)
            UIBezierPath(roundedRect:rect, cornerRadius:4).fill()
            text.draw(at:CGPoint(x:rect.minX+5, y:rect.minY+3), withAttributes:attrs)
        }
    }

    func toggleRecording() { if isRecording { stopRecording() } else { startRecording() } }
    func startRecording() { arCoordinator.startVideoRecording(); isRecording=true; showNotification("🔴 Запись...") }
    func stopRecording() { arCoordinator.stopVideoRecording { url in guard let url else{return}; saveVideoToLibrary(url); showNotification("✅ Видео сохранено") }; isRecording=false }
    func saveToLibrary(_ image:UIImage) { PHPhotoLibrary.requestAuthorization { s in guard s == .authorized else{return}; PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAsset(from:image) } } }
    func saveVideoToLibrary(_ url:URL) { PHPhotoLibrary.requestAuthorization { s in guard s == .authorized else{return}; PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:url) } } }
    func showNotification(_ msg:String) { notification=msg; DispatchQueue.main.asyncAfter(deadline:.now()+3){ notification=nil } }
}

// MARK: - Site Form Overlay

struct SiteFormOverlay: View {
    @Binding var siteID:String
    @Binding var siteName:String
    let onDone:()->Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing:20) {
                VStack(spacing:6) {
                    Text("ДАННЫЕ ОБЪЕКТА").font(.system(size:12, weight:.bold, design:.monospaced)).foregroundColor(Color(hex:"#FF6B35")!)
                    Text("Данные появятся на водяном знаке фото").font(.system(size:11)).foregroundColor(.white.opacity(0.5))
                }
                VStack(spacing:12) {
                    formField(icon:"number", placeholder:"ID сайта (напр. NTDRN_41022)", text:$siteID)
                    formField(icon:"antenna.radiowaves.left.and.right", placeholder:"Название объекта", text:$siteName)
                }
                Button { onDone() } label: {
                    Text(siteID.isEmpty && siteName.isEmpty ? "Пропустить" : "Начать съёмку")
                        .fontWeight(.semibold).foregroundColor(.white)
                        .frame(maxWidth:.infinity).frame(height:50)
                        .background(siteID.isEmpty && siteName.isEmpty ? Color.gray.opacity(0.5) : Color(hex:"#FF6B35")!)
                        .cornerRadius(14)
                }
            }
            .padding(24).background(Color(red:0.06, green:0.10, blue:0.16)).cornerRadius(20).padding(.horizontal,24)
        }
    }
    func formField(icon:String, placeholder:String, text:Binding<String>) -> some View {
        HStack(spacing:10) {
            Image(systemName:icon).foregroundColor(Color(hex:"#FF6B35")!).frame(width:20)
            TextField(placeholder, text:text).foregroundColor(.white).autocorrectionDisabled()
        }
        .padding(14).background(Color.white.opacity(0.08)).cornerRadius(12)
    }
}

// MARK: - AR Scene

struct ARSceneView: UIViewRepresentable {
    let object:AMOObject
    let coordinator:ARCoordinator
    func makeUIView(context:Context) -> ARView {
        let arView = ARView(frame:.zero)
        // WorldTracking с plane detection — как Apple AR Quick Look
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.isLightEstimationEnabled = true
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = coordinator
        // Максимальное качество — отключаем оптимизации которые снижают чёткость
        arView.renderOptions = [.disableMotionBlur, .disableDepthOfField, .disableHDR]

        // Tap — разместить мачту
        let tap = UITapGestureRecognizer(target:coordinator, action:#selector(ARCoordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        // Pinch — масштаб
        let pinch = UIPinchGestureRecognizer(target:coordinator, action:#selector(ARCoordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinch)
        // Rotation
        let rotate = UIRotationGestureRecognizer(target:coordinator, action:#selector(ARCoordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotate)
        // Pan — перемещение до фиксации
        let pan = UIPanGestureRecognizer(target:coordinator, action:#selector(ARCoordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(pan)

        coordinator.arView = arView
        coordinator.objectFileName = object.usdzFileName

        // Разрешаем одновременное распознавание жестов
        tap.delegate = coordinator
        pinch.delegate = coordinator
        rotate.delegate = coordinator
        pan.delegate = coordinator
        return arView
    }
    func updateUIView(_ uiView:ARView, context:Context) {}
}

// MARK: - Video Recorder
class ARVideoRecorder {
    private weak var arView:ARView?
    private var writer:AVAssetWriter?
    private var input:AVAssetWriterInput?
    private var adaptor:AVAssetWriterInputPixelBufferAdaptor?
    private var displayLink:CADisplayLink?
    private var outputURL:URL?
    private var startTime:CFTimeInterval = 0
    init(arView:ARView) { self.arView=arView }
    func start() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gefest_\(Date().timeIntervalSince1970).mp4")
        outputURL=url
        guard let size=arView?.bounds.size else{return}
        let w=Int(size.width*UIScreen.main.scale), h=Int(size.height*UIScreen.main.scale)
        guard let writer=try? AVAssetWriter(url:url, fileType:.mp4) else{return}
        self.writer=writer
        let input=AVAssetWriterInput(mediaType:.video, outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:w,AVVideoHeightKey:h])
        input.expectsMediaDataInRealTime=true; self.input=input
        adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input, sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:w,kCVPixelBufferHeightKey as String:h])
        writer.add(input); writer.startWriting(); writer.startSession(atSourceTime:.zero)
        startTime=CACurrentMediaTime()
        displayLink=CADisplayLink(target:self, selector:#selector(captureFrame))
        displayLink?.add(to:.main, forMode:.common)
    }
    @objc func captureFrame() {
        guard let arView,let input,input.isReadyForMoreMediaData,let pool=adaptor?.pixelBufferPool else{return}
        var pb:CVPixelBuffer?; CVPixelBufferPoolCreatePixelBuffer(nil,pool,&pb); guard let pb else{return}
        CVPixelBufferLockBaseAddress(pb,[])
        if let ctx=CGContext(data:CVPixelBufferGetBaseAddress(pb),width:CVPixelBufferGetWidth(pb),height:CVPixelBufferGetHeight(pb),bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(pb),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue){arView.layer.render(in:ctx)}
        CVPixelBufferUnlockBaseAddress(pb,[])
        adaptor?.append(pb, withPresentationTime:CMTime(seconds:CACurrentMediaTime()-startTime, preferredTimescale:600))
    }
    func stop(completion:@escaping(URL?)->Void) { displayLink?.invalidate(); displayLink=nil; input?.markAsFinished(); writer?.finishWriting{[weak self] in completion(self?.outputURL)} }
}

// MARK: - UI Components

struct ScanningOverlay: View {
    @State private var rotation:Double=0
    var body: some View {
        VStack(spacing:20) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth:2).frame(width:120, height:120)
                Circle().trim(from:0, to:0.7).stroke(Color(hex:"#00B4D8")!, lineWidth:2).frame(width:120, height:120)
                    .rotationEffect(.degrees(rotation))
                    .onAppear{withAnimation(.linear(duration:1).repeatForever(autoreverses:false)){rotation=360}}
                Image(systemName:"viewfinder").font(.system(size:40)).foregroundColor(.white.opacity(0.5))
            }
            Text("Направьте камеру на горизонтальную поверхность")
                .font(.system(size:14, weight:.medium)).foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Text("Подождите — обнаружение плоскости...")
                .font(.system(size:12, design:.monospaced)).foregroundColor(Color(hex:"#00B4D8")!)
        }
    }
}

struct CrosshairView: View {
    let color:Color
    @State private var pulse=false
    var body: some View {
        ZStack {
            Ellipse().stroke(color.opacity(0.5), lineWidth:1.5).frame(width:160, height:60).scaleEffect(pulse ? 1.05 : 1.0)
            Text("НАЖМИТЕ ДЛЯ РАЗМЕЩЕНИЯ").font(.system(size:10, weight:.semibold, design:.monospaced)).foregroundColor(color).offset(y:42)
        }
        .onAppear{withAnimation(.easeInOut(duration:0.9).repeatForever()){pulse=true}}
    }
}

struct DimensionsOverlay: View {
    let object:AMOObject; let color:Color
    var body: some View {
        VStack(alignment:.leading, spacing:6) {
            ForEach([("H",object.height),("M",object.weight),("W",object.windLoad)], id:\.0) { l,v in
                HStack(spacing:8) {
                    Text(l).font(.system(size:10, weight:.bold, design:.monospaced)).foregroundColor(color)
                    Text(v).font(.system(size:12, weight:.semibold)).foregroundColor(.white)
                }
                .padding(.horizontal,10).padding(.vertical,5).background(.ultraThinMaterial).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(color.opacity(0.3), lineWidth:1))
            }
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.topTrailing).padding(.top,120).padding(.trailing,16)
    }
}

struct SpecsOverlay: View {
    let object:AMOObject
    var body: some View {
        VStack(alignment:.leading, spacing:4) {
            Text(object.name).font(.system(size:13, weight:.bold)).foregroundColor(object.color)
            Text(object.type).font(.system(size:11)).foregroundColor(.white.opacity(0.6))
            Divider().opacity(0.2).padding(.vertical,4)
            specLine("H",object.height); specLine("M",object.weight); specLine("P",object.payload)
        }
        .padding(14).background(.ultraThinMaterial).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius:12).stroke(object.color.opacity(0.25), lineWidth:1))
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.topLeading).padding(.top,120).padding(.leading,16)
    }
    func specLine(_ l:String,_ v:String) -> some View {
        HStack(spacing:6) {
            Text(l).font(.system(size:10, weight:.bold, design:.monospaced)).foregroundColor(.white.opacity(0.4)).frame(width:16)
            Text(v).font(.system(size:12)).foregroundColor(.white)
        }
    }
}

struct NotificationToast: View {
    let message:String
    var body: some View {
        VStack {
            Spacer()
            Text(message).font(.system(size:14, weight:.medium)).foregroundColor(.white)
                .padding(.horizontal,20).padding(.vertical,12).background(.ultraThinMaterial).cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius:24).stroke(Color.white.opacity(0.15), lineWidth:1))
                .padding(.bottom,210)
        }
        .transition(.move(edge:.bottom).combined(with:.opacity))
    }
}

struct RecordingIndicator: View {
    @State private var pulse=false
    var body: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing:6) {
                    Circle().fill(Color.red).frame(width:8, height:8).scaleEffect(pulse ? 1.3:1.0)
                        .onAppear{withAnimation(.easeInOut(duration:0.7).repeatForever()){pulse=true}}
                    Text("REC").font(.system(size:12, weight:.bold, design:.monospaced)).foregroundColor(.white)
                }
                .padding(.horizontal,12).padding(.vertical,6).background(Color.red.opacity(0.8)).cornerRadius(16)
                .padding(.top,54).padding(.trailing,16)
            }
            Spacer()
        }
    }
}

struct ControlButton: View {
    let icon:String; let label:String; let isActive:Bool; let color:Color; let action:()->Void
    var body: some View {
        Button(action:action) {
            VStack(spacing:4) {
                Image(systemName:icon).font(.system(size:20))
                Text(label).font(.system(size:10))
            }
            .foregroundColor(isActive ? color : .white.opacity(0.6))
            .frame(width:64, height:54)
            .background(isActive ? color.opacity(0.15) : Color.white.opacity(0.08)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius:12).stroke(isActive ? color.opacity(0.5) : .clear, lineWidth:1))
        }
    }
}

struct ShutterButton: View {
    let isRecording:Bool; let onPress:(Bool)->Void
    @GestureState private var isLongPressing=false
    @State private var longPressTriggered=false
    var body: some View {
        ZStack {
            Circle().stroke(isRecording ? Color.red : Color.white, lineWidth:3).frame(width:72, height:72)
            Circle().fill(isRecording ? Color.red : Color.white).frame(width:58, height:58).scaleEffect(isLongPressing ? 0.85:1.0)
        }
        .simultaneousGesture(LongPressGesture(minimumDuration:0.6).updating($isLongPressing){v,s,_ in s=v}.onEnded{_ in longPressTriggered=true; onPress(true)})
        .simultaneousGesture(TapGesture().onEnded{ if !longPressTriggered{onPress(false)}; longPressTriggered=false })
        .animation(.spring(response:0.2), value:isLongPressing)
    }
}

struct GalleryThumbnailButton: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius:8).fill(Color.white.opacity(0.1)).frame(width:44, height:44)
            Image(systemName:"photo").foregroundColor(.white.opacity(0.6))
        }
    }
}

struct FlashlightButton: View {
    @State private var isOn=false
    var body: some View {
        Button { isOn.toggle(); toggleTorch(isOn) } label: {
            Image(systemName:isOn ? "bolt.fill":"bolt.slash").font(.system(size:20))
                .foregroundColor(isOn ? .yellow : .white.opacity(0.6))
                .frame(width:44, height:44).background(Color.white.opacity(0.08)).cornerRadius(22)
        }
    }
    func toggleTorch(_ on:Bool) {
        guard let device=AVCaptureDevice.default(for:.video), device.hasTorch else{return}
        try? device.lockForConfiguration(); device.torchMode=on ? .on:.off; device.unlockForConfiguration()
    }
}
