//
//  WebcamView.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 19/08/24.
//

import AVFoundation
import Defaults
import SwiftUI

struct CameraPreviewView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var webcamManager: WebcamManager
    
    // Track if authorization request is in progress to avoid multiple requests
    @State private var isRequestingAuthorization: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let previewLayer = webcamManager.previewLayer {
                    CameraPreviewLayerView(previewLayer: previewLayer)
                        .clipShape(RoundedRectangle(cornerRadius: Defaults[.mirrorShape] == .rectangle ? !Defaults[.cornerRadiusScaling] ? MusicPlayerImageSizes.cornerRadiusInset.closed : MusicPlayerImageSizes.cornerRadiusInset.opened : 100))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .opacity(webcamManager.isSessionRunning ? 1 : 0)
                }

                if !webcamManager.isSessionRunning {
                    ZStack {
                        RoundedRectangle(cornerRadius: Defaults[.mirrorShape] == .rectangle ? !Defaults[.cornerRadiusScaling] ? MusicPlayerImageSizes.cornerRadiusInset.closed : 12 : 100)
                            .fill(Color(red: 20/255, green: 20/255, blue: 20/255))
                            .strokeBorder(.white.opacity(0.04), lineWidth: 1)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                        VStack(spacing: 8) {
                            if webcamManager.authorizationStatus == .denied {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: geometry.size.width/3.5))
                                Text("Access Denied")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            } else if !webcamManager.cameraAvailable {
                                Image(systemName: "video.slash")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: geometry.size.width/3.5))
                                Text("No Camera")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Button(action: {
                                    HapticHelper.trigger()
                                    webcamManager.checkCameraAvailability()
                                    webcamManager.startSession()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Retry connecting")
                            } else {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .contextMenu {
                if !webcamManager.availableDevices.isEmpty {
                    Menu("Switch Camera") {
                        ForEach(webcamManager.availableDevices, id: \.uniqueID) { device in
                            Button(action: {
                                HapticHelper.trigger()
                                Defaults[.selectedCameraID] = device.uniqueID
                                if webcamManager.isSessionRunning {
                                    webcamManager.stopSession()
                                    webcamManager.startSession()
                                }
                            }) {
                                HStack {
                                    if Defaults[.selectedCameraID] == device.uniqueID {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(device.localizedName)
                                }
                            }
                        }
                    }
                }
                Button("Refresh Camera List") {
                    HapticHelper.trigger()
                    webcamManager.checkCameraAvailability()
                }
            }
            .onDisappear {
                webcamManager.stopSession()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            // Request permission first
            webcamManager.checkAndRequestVideoAuthorization()
            
            // Auto-start camera when view appears
            if !webcamManager.isSessionRunning {
                webcamManager.startSession()
            }
        }
    }
}


struct CameraPreviewLayerView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> _CameraHostView {
        let host = _CameraHostView()
        host.setPreviewLayer(previewLayer)
        return host
    }

    func updateNSView(_ nsView: _CameraHostView, context: Context) {
        // Re-attach layer if session was recreated (stopSession → startSession
        // creates a new AVCaptureVideoPreviewLayer instance).
        if nsView.hostedLayer !== previewLayer {
            nsView.setPreviewLayer(previewLayer)
        }
        nsView.needsLayout = true
    }
}

/// Layer-hosting NSView: sets self.layer = previewLayer so AppKit drives
/// all geometry. layout() is called every time bounds change (including the
/// first real layout pass after SwiftUI commits a non-zero frame), which
/// eliminates the zero-frame race in makeNSView.
final class _CameraHostView: NSView {
    private(set) var hostedLayer: AVCaptureVideoPreviewLayer?

    override var wantsUpdateLayer: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        // wantsLayer must be true before setting self.layer
        wantsLayer = true
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        hostedLayer = layer
        layer.videoGravity = .resizeAspectFill
        // Layer-hosting: replacing self.layer atomically is sufficient;
        // calling removeFromSuperlayer() on a root layer is unsafe and unnecessary.
        self.layer = layer
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard let l = hostedLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Keep the root layer's bounds in sync with the view's bounds so the
        // preview fills the view on every layout pass (including the first
        // real pass that follows SwiftUI's initial zero-size assignment).
        l.bounds = self.bounds
        CATransaction.commit()
    }
}

#Preview {
    CameraPreviewView(webcamManager: .shared)
}
