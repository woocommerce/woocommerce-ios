extension ARCuboidEntity {
    /// One of the six faces of the cuboid, identified by which axis the face
    /// is perpendicular to and which side along that axis it sits on. With the
    /// cuboid centred on its X/Z root and rising from local Y 0 to 1, the
    /// `+X` face is at world `+x`, the `+Y` face is the top, etc.
    struct Face: Hashable {
        let axis: Axis
        let isPositiveSide: Bool

        static let positiveX = Face(axis: .x, isPositiveSide: true)
        static let negativeX = Face(axis: .x, isPositiveSide: false)
        static let positiveY = Face(axis: .y, isPositiveSide: true)
        static let negativeY = Face(axis: .y, isPositiveSide: false)
        static let positiveZ = Face(axis: .z, isPositiveSide: true)
        static let negativeZ = Face(axis: .z, isPositiveSide: false)

        fileprivate var bitIndex: Int { axis.simdIndex * 2 + (isPositiveSide ? 1 : 0) }
    }

    /// Stack-allocated set of faces backed by a 6-bit mask. Avoids the
    /// per-frame heap allocation that Set<Face> would incur.
    struct FaceSet: Equatable {
        private var bits: UInt8 = 0

        static let empty = FaceSet()

        mutating func insert(_ face: Face) {
            bits |= 1 << face.bitIndex
        }

        func contains(_ face: Face) -> Bool {
            bits & (1 << face.bitIndex) != 0
        }

        var isEmpty: Bool { bits == 0 }

        init() {}

        init(_ faces: Face...) {
            for face in faces { insert(face) }
        }
    }
}
