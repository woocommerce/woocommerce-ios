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
    }
}
