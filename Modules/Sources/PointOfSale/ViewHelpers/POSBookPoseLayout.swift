import SwiftUI

/// Uses the local division region to keep each pane on its own page in book pose.
struct POSBookPoseLayout: Equatable {
    let leadingWidth: CGFloat
    let trailingWidth: CGFloat
    let spacing: CGFloat

    init(geometry: GeometryProxy, defaultLeadingFraction: CGFloat) {
        let divisionFrames: [CGRect]
        // The iOS 27.1 SDK ships SwiftUI 8.0.85.27; older SDKs do not declare this API.
        #if canImport(SwiftUI, _version: 8.0.85.27)
        if #available(iOS 27.1, *) {
            divisionFrames = geometry.reservedRegions(kind: .division)
                .filter(\.isActive)
                .map(\.frame)
        } else {
            divisionFrames = []
        }
        #else
        divisionFrames = []
        #endif
        self.init(size: geometry.size, defaultLeadingFraction: defaultLeadingFraction, divisionFrames: divisionFrames)
    }

    /// Frames use semantic local coordinates, including the system's division margins.
    init(size: CGSize, defaultLeadingFraction: CGFloat, divisionFrames: [CGRect] = []) {
        if let division = divisionFrames.first(where: { frame in
            frame.origin.x.isFinite && frame.origin.y.isFinite
                && frame.width.isFinite && frame.height.isFinite
                && frame.width > 0 && frame.height > 0
                && frame.minY <= 0 && frame.maxY >= size.height
                && frame.minX > 0 && frame.maxX < size.width
        }) {
            leadingWidth = division.minX
            trailingWidth = size.width - division.maxX
            spacing = division.width
        } else {
            leadingWidth = size.width * defaultLeadingFraction
            trailingWidth = size.width - leadingWidth
            spacing = 0
        }
    }
}
