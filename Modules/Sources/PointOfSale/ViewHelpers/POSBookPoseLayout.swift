import SwiftUI

/// Uses the local division region to keep each pane on its own page in book pose.
struct POSBookPoseLayout {
    let leadingWidth: CGFloat
    let trailingWidth: CGFloat
    let spacing: CGFloat
    let hasDivisionRegion: Bool
    let contentPadding: POSContentPaddingContext

    /// Backgrounds meet at the fold; only content leaves the division gap empty.
    var backgroundLeadingWidth: CGFloat { leadingWidth + spacing / 2 }

    init(geometry: GeometryProxy, defaultLeadingFraction: CGFloat) {
        // The iOS 27.1 SDK ships SwiftUI 8.0.85.27; older SDKs do not declare this API.
        #if canImport(SwiftUI, _version: 8.0.85.27)
        if #available(iOS 27.1, *) {
            let regions = geometry.reservedRegions(kind: .division, options: .includeInactive)
            let activeRegions = regions.filter(\.isActive)
            self.init(size: geometry.size, defaultLeadingFraction: defaultLeadingFraction,
                      divisionFrames: activeRegions.map(\.frame), hasDivisionRegion: !regions.isEmpty,
                      contentPadding: POSContentPaddingContext(bounds: geometry.frame(in: .global),
                                                               regions: activeRegions.map { ($0.frame, $0.margins) }))
            return
        }
        #endif
        self.init(size: geometry.size, defaultLeadingFraction: defaultLeadingFraction)
    }

    /// Frames use semantic local coordinates, including the system's division margins.
    init(size: CGSize, defaultLeadingFraction: CGFloat, divisionFrames: [CGRect] = [], hasDivisionRegion: Bool = false,
         contentPadding: POSContentPaddingContext = POSContentPaddingContext()) {
        self.hasDivisionRegion = hasDivisionRegion || !divisionFrames.isEmpty
        self.contentPadding = contentPadding
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

private struct POSBookPoseAnimationModifier: ViewModifier {
    let layout: POSBookPoseLayout
    @State private var hasInitialDivision = false

    func body(content: Content) -> some View {
        content
            .animation(hasInitialDivision ? .default : nil, value: layout.spacing > 0)
            // The first reported region seeds the layout; later pose changes animate.
            .onChange(of: layout.hasDivisionRegion, initial: true) { _, hasDivisionRegion in
                if hasDivisionRegion { hasInitialDivision = true }
            }
            .onDisappear { hasInitialDivision = false }
    }
}

extension View {
    func posBookPoseAnimation(_ layout: POSBookPoseLayout) -> some View {
        modifier(POSBookPoseAnimationModifier(layout: layout))
    }
}
