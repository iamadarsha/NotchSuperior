// ────────────────────────────────────────────────────────
// NotchSuperior — NSCameraView.swift
// Part of the boring.notch fork
// Phase: 11 — Camera Mirror Tab
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// Front-camera preview with mirror mode and snapshot capture.
// Fits within openNotchSize (640×190pt).
// ────────────────────────────────────────────────────────

import SwiftUI
import AVFoundation

@available(macOS 14.0, *)
struct NSCameraView: View {
    @State private var permissionGranted: Bool = false
    @State private var permissionChecked: Bool = false
    @State private var snapshotFeedback: Bool = false
    @State private var captureRef: CameraPreviewNSView?

    var body: some View {
        ZStack {
            if permissionChecked {
                if permissionGranted {
                    NSAVCameraPreviewView(captureRef: $captureRef)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            cameraOverlay
                        }
                        .overlay(alignment: .topLeading) {
                            liveBadge
                        }
                } else {
                    permissionPrompt
                }
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .frame(maxWidth: 640, maxHeight: 190)
        .onAppear { checkPermission() }
    }

    // MARK: - Overlays

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            Text("LIVE")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial.opacity(0.8), in: Capsule())
        .padding(8)
    }

    private var cameraOverlay: some View {
        HStack(spacing: 8) {
            // Snapshot button
            Button(action: takeSnapshot) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.85))
                        .frame(width: 32, height: 32)
                    Image(systemName: snapshotFeedback ? "checkmark" : "camera.shutter.button")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(snapshotFeedback ? .green : .white)
                        .animation(.easeInOut(duration: 0.2), value: snapshotFeedback)
                }
            }
            .buttonStyle(.plain)
            .help("Save snapshot to Desktop")
        }
        .padding(8)
    }

    private var permissionPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.fill")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text("Camera access needed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Button("Open Privacy Settings") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Actions

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            permissionChecked = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    permissionGranted = granted
                    permissionChecked = true
                }
            }
        default:
            permissionGranted = false
            permissionChecked = true
        }
    }

    private func takeSnapshot() {
        guard let view = captureRef else { return }
        view.captureSnapshot { image in
            guard let image else { return }
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let name = "NotchSuperior_\(fmt.string(from: Date())).png"
            let url = desktop.appendingPathComponent(name)
            if let tiff = image.tiffRepresentation,
               let bmp = NSBitmapImageRep(data: tiff),
               let png = bmp.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
            }
            snapshotFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                snapshotFeedback = false
            }
        }
    }
}

// MARK: - AVFoundation NSView wrapper

@available(macOS 14.0, *)
private struct NSAVCameraPreviewView: NSViewRepresentable {
    @Binding var captureRef: CameraPreviewNSView?

    func makeNSView(context: Context) -> CameraPreviewNSView {
        let v = CameraPreviewNSView()
        DispatchQueue.main.async { captureRef = v }
        return v
    }
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {}
}

@available(macOS 14.0, *)
class CameraPreviewNSView: NSView {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.notchsuperior.cameraQueue", qos: .userInitiated)
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let photoOutput = AVCapturePhotoOutput()
    private var pendingSnapshotHandler: ((NSImage?) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    deinit {
        let s = session; let q = sessionQueue
        q.async { s.stopRunning() }
    }

    private func setup() {
        wantsLayer = true
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        preview.frame = bounds
        layer = preview
        previewLayer = preview
        startSession()
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .external],
                mediaType: .video,
                position: .unspecified
            )
            guard let cam = discovery.devices.first else {
                self.session.commitConfiguration(); return
            }
            do {
                let input = try AVCaptureDeviceInput(device: cam)
                if self.session.canAddInput(input) { self.session.addInput(input) }
            } catch {
                self.session.commitConfiguration(); return
            }
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                if let conn = self.previewLayer?.connection,
                   conn.isVideoMirroringSupported {
                    conn.automaticallyAdjustsVideoMirroring = false
                    conn.isVideoMirrored = true
                }
            }
        }
    }

    func captureSnapshot(completion: @escaping (NSImage?) -> Void) {
        pendingSnapshotHandler = completion
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

@available(macOS 14.0, *)
extension CameraPreviewNSView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let handler = pendingSnapshotHandler
        pendingSnapshotHandler = nil
        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { handler?(nil) }
            return
        }
        let image = NSImage(data: data)
        DispatchQueue.main.async { handler?(image) }
    }
}
