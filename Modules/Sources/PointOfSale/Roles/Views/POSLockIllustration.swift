import SwiftUI

struct POSLockIllustration: View {
    static let size: CGFloat = 88
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let isOpen: Bool

    init(isOpen: Bool = false) {
        self.isOpen = isOpen
    }

    var body: some View {
        ZStack {
            shackle
                .rotationEffect(.degrees(isOpen && !reduceMotion ? Constants.openAngle : 0), anchor: Constants.hinge)
            artwork
                .mask(alignment: .bottom) {
                    Rectangle().frame(height: Constants.artworkHeight - Constants.shackleHeight)
                }
        }
        .frame(width: Constants.artworkWidth, height: Constants.artworkHeight)
        .frame(width: Self.size, height: Self.size)
        .accessibilityHidden(true)
    }
}

private extension POSLockIllustration {
    var artwork: some View {
        PointOfSaleAssets.lock.decorativeImage.resizable().scaledToFit()
    }

    var shackle: some View {
        ZStack(alignment: .topLeading) {
            PointOfSaleAssets.lockShackleFill.decorativeImage.resizable().scaledToFit()
                .frame(width: Constants.fillSize.width, height: Constants.fillSize.height)
                .offset(x: Constants.shackleFillOrigin.x, y: Constants.shackleFillOrigin.y)
            PointOfSaleAssets.lockShackleStroke.decorativeImage.resizable().scaledToFit()
                .frame(width: Constants.strokeSize.width, height: Constants.strokeSize.height)
                .offset(x: Constants.shackleStrokeOriginX)
        }
        .frame(width: Constants.artworkWidth, height: Constants.artworkHeight, alignment: .topLeading)
    }

    enum Constants {
        static let artworkWidth: CGFloat = 60.456
        static let artworkHeight: CGFloat = 80
        // The complete source shackle rotates behind the fixed body and hinge caps.
        static let shackleHeight: CGFloat = 24.43
        static let shackleFillOrigin = CGPoint(x: 10.684, y: 0.9121)
        static let shackleStrokeOriginX: CGFloat = 9.772
        static let fillSize = CGSize(width: 39.0879, height: 35.8306)
        static let strokeSize = CGSize(width: 40.9121, height: 37.6547)
        static let hinge = UnitPoint(x: 45.7003 / artworkWidth, y: 27.785 / artworkHeight)
        static let openAngle: Double = 30
    }
}

#if DEBUG
extension POSLockIllustration {
    /// The first frame of the closing animation, for previews and snapshots.
    static var open: POSLockIllustration {
        POSLockIllustration(isOpen: true)
    }
}

#Preview("Open and closed") {
    HStack {
        POSLockIllustration.open
        POSLockIllustration()
    }
    .posPadding(\.medium)
}
#endif
