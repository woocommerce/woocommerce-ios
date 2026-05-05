extension ARCuboidEntity {
    /// One of the six faces of the cuboid, identified by which axis the face
    /// is perpendicular to and which side along that axis it sits on. With the
    /// cuboid centred on its X/Z root and rising from local Y 0 to 1, the
    /// `+X` face is at world `+x`, the `+Y` face is the top, etc.
    enum Face {
        case positiveX, negativeX, positiveY, negativeY, positiveZ, negativeZ

        init(axis: Axis, isPositiveSide: Bool) {
            switch (axis, isPositiveSide) {
            case (.x, true): self = .positiveX
            case (.x, false): self = .negativeX
            case (.y, true): self = .positiveY
            case (.y, false): self = .negativeY
            case (.z, true): self = .positiveZ
            case (.z, false): self = .negativeZ
            }
        }

        var axis: Axis {
            switch self {
            case .positiveX, .negativeX: return .x
            case .positiveY, .negativeY: return .y
            case .positiveZ, .negativeZ: return .z
            }
        }

        var isPositiveSide: Bool {
            switch self {
            case .positiveX, .positiveY, .positiveZ: return true
            case .negativeX, .negativeY, .negativeZ: return false
            }
        }

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
