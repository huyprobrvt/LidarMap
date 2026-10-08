import ARKit
import RealityKit
import UIKit

enum ScanState {
    case idle
    case scanning
    case stopped
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Điều khiển phiên quét LiDAR. Mọi hàm công khai được gọi từ luồng chính (nút bấm SwiftUI).
final class ScanController: NSObject, ObservableObject {

    @Published var state: ScanState = .idle
    @Published var supported = true
    @Published var triangleCount = 0
    @Published var anchorCount = 0
    @Published var elapsed: TimeInterval = 0
    @Published var trackingText = "Sẵn sàng"
    @Published var trackingOK = true
    @Published var lightText = ""
    @Published var exporting = false
    @Published var shareItem: ShareItem?
    @Published var infoText: String?
    @Published var errorText: String?

    private weak var arView: ARView?
    private var timer: Timer?
    private var startDate: Date?
    private var snapshot: [ARMeshAnchor] = []

    // MARK: - Gắn khung nhìn AR

    func attach(_ view: ARView) {
        arView = view
        let meshOK = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        DispatchQueue.main.async {
            self.supported = meshOK
        }
        // Chạy phiên không có lưới để người dùng thấy camera và ngắm trước khi bấm quét.
        view.session.run(ARWorldTrackingConfiguration())
    }

    // MARK: - Bắt đầu, dừng, quét lại

    func start() {
        guard let arView = arView else { return }
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            supported = false
            errorText = "Máy này không có cảm biến LiDAR nên không quét được lưới."
            return
        }
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else {
            config.sceneReconstruction = .mesh
        }
        config.environmentTexturing = .none
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        snapshot = []
        triangleCount = 0
        anchorCount = 0
        elapsed = 0
        infoText = nil
        startDate = Date()
        state = .scanning
        UIApplication.shared.isIdleTimerDisabled = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        guard state == .scanning else { return }
        snapshot = currentMeshAnchors()
        arView?.session.pause()
        timer?.invalidate()
        timer = nil
        state = .stopped
        UIApplication.shared.isIdleTimerDisabled = false
        trackingText = "Đã dừng"
        trackingOK = true
        lightText = ""
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        snapshot = []
        triangleCount = 0
        anchorCount = 0
        elapsed = 0
        infoText = nil
        arView?.debugOptions.remove(.showSceneUnderstanding)
        arView?.session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
        state = .idle
        trackingText = "Sẵn sàng"
        trackingOK = true
        lightText = ""
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Cập nhật thông số hiển thị (2 lần mỗi giây)

    private func currentMeshAnchors() -> [ARMeshAnchor] {
        guard let frame = arView?.session.currentFrame else { return [] }
        return frame.anchors.compactMap { $0 as? ARMeshAnchor }
    }

    private func tick() {
        guard state == .scanning, let frame = arView?.session.currentFrame else { return }

        var triangles = 0
        var meshes = 0
        for anchor in frame.anchors {
            if let mesh = anchor as? ARMeshAnchor {
                meshes += 1
                triangles += mesh.geometry.faces.count
            }
        }
        triangleCount = triangles
        anchorCount = meshes
        elapsed = Date().timeIntervalSince(startDate ?? Date())

        switch frame.camera.trackingState {
        case .normal:
            trackingText = "Theo dõi tốt"
            trackingOK = true
        case .notAvailable:
            trackingText = "Không theo dõi được"
            trackingOK = false
        case .limited(let reason):
            trackingOK = false
            switch reason {
            case .excessiveMotion:
                trackingText = "Di chuyển chậm lại"
            case .insufficientFeatures:
                trackingText = "Thiếu chi tiết bề mặt, hướng máy vào vùng có đồ vật"
            case .initializing:
                trackingText = "Đang khởi tạo"
            case .relocalizing:
                trackingText = "Đang định vị lại"
            @unknown default:
                trackingText = "Theo dõi bị hạn chế"
            }
        @unknown default:
            trackingText = "Theo dõi bị hạn chế"
            trackingOK = false
        }

        var hints: [String] = []
        if let estimate = frame.lightEstimate, estimate.ambientIntensity < 250 {
            hints.append("Thiếu sáng, hãy bật thêm đèn")
        }
        if elapsed > 300 {
            hints.append("Đã quét trên 5 phút, nên dừng và xuất để tránh trôi")
        }
        lightText = hints.joined(separator: ". ")
    }

    // MARK: - Xuất PLY

    func exportPLY() {
        let anchors = (state == .scanning) ? currentMeshAnchors() : snapshot
        if anchors.isEmpty {
            errorText = "Chưa có lưới nào để xuất. Hãy quét trước."
            return
        }
        exporting = true

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let name = "quet_" + formatter.string(from: Date()) + ".ply"
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = folder.appendingPathComponent(name)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let summary = try MeshExporter.writePLY(anchors: anchors, to: url)
                let megabytes = Double(summary.fileBytes) / 1_048_576.0
                let text = String(
                    format: "%@: %d đỉnh, %d tam giác, %.1f MB, cỡ %.1f × %.1f × %.1f m",
                    name, summary.vertices, summary.triangles, megabytes,
                    summary.extent.x, summary.extent.y, summary.extent.z
                )
                DispatchQueue.main.async {
                    self?.exporting = false
                    self?.infoText = text
                    self?.shareItem = ShareItem(url: url)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.exporting = false
                    self?.errorText = "Không ghi được tệp: \(error.localizedDescription)"
                }
            }
        }
    }
}
