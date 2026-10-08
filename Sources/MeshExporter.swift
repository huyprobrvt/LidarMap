import ARKit
import Metal
import simd

/// Gộp toàn bộ ARMeshAnchor thành một lưới duy nhất trong toạ độ thế giới của ARKit
/// (trục Y hướng lên, đơn vị mét, gốc là nơi phiên quét bắt đầu) rồi ghi ra PLY nhị phân.
enum MeshExporter {

    struct Summary {
        let vertices: Int
        let triangles: Int
        let fileBytes: Int
        let extent: SIMD3<Float>
    }

    enum ExportError: Error {
        case emptyMesh
    }

    static func writePLY(anchors: [ARMeshAnchor], to url: URL) throws -> Summary {
        var vertexBytes = [UInt8]()
        var faceBytes = [UInt8]()
        var vertexCount = 0
        var faceCount = 0
        var minP = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var maxP = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)

        for anchor in anchors {
            let geometry = anchor.geometry
            let vertices = geometry.vertices
            let faces = geometry.faces
            if vertices.count == 0 || faces.count == 0 || faces.indexCountPerPrimitive != 3 {
                continue
            }

            let transform = anchor.transform
            let base = vertexCount
            let vertexPointer = vertices.buffer.contents()

            vertexBytes.reserveCapacity(vertexBytes.count + vertices.count * 12)
            for i in 0..<vertices.count {
                let offset = vertices.offset + vertices.stride * i
                let x = vertexPointer.load(fromByteOffset: offset, as: Float.self)
                let y = vertexPointer.load(fromByteOffset: offset + 4, as: Float.self)
                let z = vertexPointer.load(fromByteOffset: offset + 8, as: Float.self)
                let world = transform * SIMD4<Float>(x, y, z, 1)
                let p = SIMD3<Float>(world.x, world.y, world.z)
                minP = pointwiseMin(minP, p)
                maxP = pointwiseMax(maxP, p)
                appendFloat(&vertexBytes, p.x)
                appendFloat(&vertexBytes, p.y)
                appendFloat(&vertexBytes, p.z)
            }
            vertexCount += vertices.count

            let indexPointer = faces.buffer.contents()
            let bytesPerIndex = faces.bytesPerIndex
            faceBytes.reserveCapacity(faceBytes.count + faces.count * 13)
            for f in 0..<faces.count {
                faceBytes.append(3)
                for k in 0..<3 {
                    let index = readIndex(indexPointer, (f * 3 + k) * bytesPerIndex, bytesPerIndex)
                    appendInt32(&faceBytes, Int32(base + index))
                }
            }
            faceCount += faces.count
        }

        if vertexCount == 0 || faceCount == 0 {
            throw ExportError.emptyMesh
        }

        let header =
            "ply\n" +
            "format binary_little_endian 1.0\n" +
            "comment LidarMap ARKit world, y-up, meters\n" +
            "element vertex \(vertexCount)\n" +
            "property float x\n" +
            "property float y\n" +
            "property float z\n" +
            "element face \(faceCount)\n" +
            "property list uchar int vertex_indices\n" +
            "end_header\n"

        var data = Data(header.utf8)
        data.append(contentsOf: vertexBytes)
        data.append(contentsOf: faceBytes)
        try data.write(to: url, options: .atomic)

        return Summary(vertices: vertexCount, triangles: faceCount, fileBytes: data.count, extent: maxP - minP)
    }

    // MARK: - Ghi và đọc byte

    private static func readIndex(_ pointer: UnsafeMutableRawPointer, _ offset: Int, _ bytesPerIndex: Int) -> Int {
        if bytesPerIndex == 2 {
            return Int(pointer.load(fromByteOffset: offset, as: UInt16.self))
        }
        return Int(pointer.load(fromByteOffset: offset, as: UInt32.self))
    }

    private static func appendUInt32(_ bytes: inout [UInt8], _ value: UInt32) {
        bytes.append(UInt8(truncatingIfNeeded: value))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    }

    private static func appendFloat(_ bytes: inout [UInt8], _ value: Float) {
        appendUInt32(&bytes, value.bitPattern)
    }

    private static func appendInt32(_ bytes: inout [UInt8], _ value: Int32) {
        appendUInt32(&bytes, UInt32(bitPattern: value))
    }
}
