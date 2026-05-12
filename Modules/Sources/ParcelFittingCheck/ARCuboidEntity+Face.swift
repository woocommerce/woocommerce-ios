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

        var faceSetMember: FaceSet {
            switch self {
            case .positiveX: return .positiveX
            case .negativeX: return .negativeX
            case .positiveY: return .positiveY
            case .negativeY: return .negativeY
            case .positiveZ: return .positiveZ
            case .negativeZ: return .negativeZ
            }
        }
    }

    /// Stack-allocated set of faces backed by a 6-bit mask.
    struct FaceSet: OptionSet, Equatable {
        let rawValue: UInt8

        static let positiveX = FaceSet(rawValue: 1 << 0)
        static let negativeX = FaceSet(rawValue: 1 << 1)
        static let positiveY = FaceSet(rawValue: 1 << 2)
        static let negativeY = FaceSet(rawValue: 1 << 3)
        static let positiveZ = FaceSet(rawValue: 1 << 4)
        static let negativeZ = FaceSet(rawValue: 1 << 5)

        static let empty: FaceSet = []

        init(rawValue: UInt8) { self.rawValue = rawValue }

        init(_ face: Face) { self = face.faceSetMember }

        init(_ a: Face, _ b: Face) { self = [a.faceSetMember, b.faceSetMember] }

        func contains(_ face: Face) -> Bool {
            contains(face.faceSetMember)
        }
    }
}
