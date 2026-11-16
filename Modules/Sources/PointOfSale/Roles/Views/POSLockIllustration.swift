import SwiftUI

/// The padlock on the POS lock screen. It appears open and then closes to confirm that POS is locked.
/// The lock screen is already fully shown underneath, so the animation never delays protection.
struct POSLockIllustration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isClosed: Bool
    private let animatesClosing: Bool

    init(animatesClosing: Bool = true) {
        self.init(isClosed: !animatesClosing, animatesClosing: animatesClosing)
    }

    private init(isClosed: Bool, animatesClosing: Bool) {
        self._isClosed = State(initialValue: isClosed)
        self.animatesClosing = animatesClosing
    }

    var body: some View {
        ZStack {
            artwork
                .mask(alignment: .top) {
                    Rectangle().frame(height: Constants.shackleHeight)
                }
                .offset(y: isShowingClosed ? 0 : -Constants.openShackleOffset)
            artwork
                .mask(alignment: .bottom) {
                    Rectangle().frame(height: Constants.artworkHeight - Constants.shackleHeight)
                }
        }
        .frame(width: Constants.artworkWidth, height: Constants.artworkHeight)
        .frame(width: Constants.size, height: Constants.size)
        .accessibilityHidden(true)
        .onAppear {
            guard animatesClosing, !isClosed, !reduceMotion else { return }
            withAnimation(Constants.closingAnimation) {
                isClosed = true
            }
        }
    }
}

private extension POSLockIllustration {
    var artwork: some View {
        PointOfSaleAssets.lock.decorativeImage.resizable().scaledToFit()
    }

    var isShowingClosed: Bool {
        isClosed || reduceMotion
    }

    enum Constants {
        static let size: CGFloat = 88
        static let artworkWidth: CGFloat = 60.4561
        static let artworkHeight: CGFloat = 80
        // Split above the fixed hinge caps, preserving the unmodified Figma vector when closed.
        static let shackleHeight: CGFloat = 24.43
        static let openShackleOffset: CGFloat = 12
        // Long enough for the open lock to register before it closes.
        static let closingAnimation: Animation = .spring(duration: 0.35, bounce: 0.35).delay(0.4)
    }
}

#if DEBUG
extension POSLockIllustration {
    /// The first frame of the closing animation, for previews and snapshots.
    static var open: POSLockIllustration {
        POSLockIllustration(isClosed: false, animatesClosing: false)
    }
}

#Preview("Open and closed") {
    HStack {
        POSLockIllustration.open
        POSLockIllustration(animatesClosing: false)
    }
    .posPadding(\.medium)
}
#endif
