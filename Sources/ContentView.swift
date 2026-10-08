import SwiftUI
import ARKit
import RealityKit

// MARK: - Khung nhìn AR

struct ARViewContainer: UIViewRepresentable {
    let controller: ScanController

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        controller.attach(view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Bảng chia sẻ (AirDrop, Lưu vào Tệp, Zalo, email...)

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Màn hình chính

struct ContentView: View {
    @StateObject private var scan = ScanController()

    var body: some View {
        ZStack {
            ARViewContainer(controller: scan)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                statusCard
                Spacer()
                if scan.exporting {
                    ProgressView("Đang ghi tệp PLY…")
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                controls
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .sheet(item: $scan.shareItem) { item in
            ShareSheet(url: item.url)
        }
        .alert("Thông báo", isPresented: errorBinding) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(scan.errorText ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { scan.errorText != nil },
            set: { shown in
                if !shown { scan.errorText = nil }
            }
        )
    }

    // MARK: Thẻ trạng thái

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch scan.state {
            case .idle:
                Text("Sẵn sàng quét")
                    .font(.headline)
                Text("Đi chậm một vòng khép kín, quét từ sàn lên trần, giữ máy cách tường 1 đến 3 m. Mỗi lần chỉ quét một phòng.")
                    .font(.footnote)
            case .scanning:
                HStack {
                    Circle()
                        .fill(scan.trackingOK ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)
                    Text(scan.trackingText)
                        .font(.headline)
                    Spacer()
                    Text(timeString(scan.elapsed))
                        .font(.headline.monospacedDigit())
                }
                Text("\(scan.triangleCount) tam giác · \(scan.anchorCount) mảnh lưới")
                    .font(.footnote.monospacedDigit())
                if !scan.lightText.isEmpty {
                    Text(scan.lightText)
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            case .stopped:
                Text("Đã dừng · \(scan.triangleCount) tam giác · \(timeString(scan.elapsed))")
                    .font(.headline)
                if let info = scan.infoText {
                    Text(info)
                        .font(.footnote)
                } else {
                    Text("Bấm Xuất PLY để lưu tệp. Tệp cũng nằm trong ứng dụng Tệp, mục Trên iPhone của tôi, thư mục LidarMap.")
                        .font(.footnote)
                }
            }
            if !scan.supported {
                Text("Máy này không có LiDAR, ứng dụng không quét được lưới.")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Nút điều khiển

    @ViewBuilder
    private var controls: some View {
        switch scan.state {
        case .idle:
            Button {
                scan.start()
            } label: {
                Text("Bắt đầu quét")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!scan.supported)
        case .scanning:
            Button {
                scan.stop()
            } label: {
                Text("Dừng quét")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        case .stopped:
            HStack(spacing: 10) {
                Button {
                    scan.reset()
                } label: {
                    Text("Quét lại")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                Button {
                    scan.exportPLY()
                } label: {
                    Text("Xuất PLY")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(scan.exporting)
            }
        }
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
