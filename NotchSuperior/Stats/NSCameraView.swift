// ────────────────────────────────────────────────────────
// NotchSuperior — NSCameraView.swift
// Part of the boring.notch fork
// Phase: 11 — Camera Mirror Tab
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// Front-camera preview, mirrored like a mirror.
// Fits within openNotchSize (640×190pt).
// ────────────────────────────────────────────────────────

import SwiftUI
import AVFoundation

@available(macOS 14.0, *)
struct NSCameraView: View {
    @State private var permissionGranted: Bool = false
    @State private var permissionChecked: Bool = false

    var body: some View {
        ZStack {
            if permissionChecked {
                if permissionGranted {
                    NSAVCameraPreviewView()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                } else {
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
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .frame(maxWidth: 640, maxHeight: 190)
        .onAppear { checkPermission() }
    }

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
}

// MARK: - AVFoundation NSView wrapper

private struct NSAVCameraPreviewView: NSViewRepresentable {
    func makeNSView(context: Context) -> CameraPreviewNSView {
        CameraPreviewNSView()
    }
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {}

    class CameraPreviewNSView: NSView {
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "com.notchsuperior.cameraQueue", qos: .userInitiated)
        private var previewLayer: AVCaptureVideoPreviewLayer?

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
                self.session.commitConfiguration()
                self.session.startRunning()

                DispatchQueue.main.async {
                    // Mirror so it looks like a real mirror
                    if let conn = self.previewLayer?.connection,
                       conn.isVideoMirroringSupported {
                        conn.automaticallyAdjustsVideoMirroring = false
                        conn.isVideoMirrored = true
                    }
                }
            }
        }
    }
}
