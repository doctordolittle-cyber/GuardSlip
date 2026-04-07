import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var animateScanner = false

    var body: some View {
        ZStack {
            Color("BackgroundPrimary").ignoresSafeArea()

            BarcodeCameraPreview(onCodeDetected: { code in
                guard scannedCode == nil else { return }
                scannedCode = code
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onCodeScanned(code)
                dismiss()
            })
            .ignoresSafeArea()

            scannerOverlay

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                            .frame(width: 36, height: 36)
                            .background(Color("BackgroundSecondary").opacity(0.8))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                Text("Point camera at barcode or serial number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color("BackgroundSecondary").opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 60)
            }
        }
    }

    private var scannerOverlay: some View {
        GeometryReader { geo in
            let size = min(geo.size.width * 0.7, 280.0)
            let rect = CGRect(
                x: (geo.size.width - size) / 2,
                y: (geo.size.height - size) / 2 - 40,
                width: size,
                height: size
            )

            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .mask {
                        Rectangle()
                            .ignoresSafeArea()
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            }
                    }

                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("AccentPrimary"), lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentPrimary").opacity(0), Color("AccentPrimary").opacity(0.6), Color("AccentPrimary").opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: rect.width - 20, height: 2)
                    .position(x: rect.midX, y: rect.minY + (animateScanner ? rect.height - 10 : 10))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            animateScanner = true
                        }
                    }
            }
        }
    }
}

private struct BarcodeCameraPreview: UIViewRepresentable {
    let onCodeDetected: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let session = AVCaptureSession()
        context.coordinator.session = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return view
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .code128, .code39, .code93, .qr, .upce, .pdf417]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeDetected: onCodeDetected)
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        let onCodeDetected: (String) -> Void

        init(onCodeDetected: @escaping (String) -> Void) {
            self.onCodeDetected = onCodeDetected
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue else { return }
            session?.stopRunning()
            onCodeDetected(code)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.session?.stopRunning()
    }
}
