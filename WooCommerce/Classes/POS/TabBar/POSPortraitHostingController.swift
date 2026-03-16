import SwiftUI

/// A hosting controller that locks its content to portrait orientation.
/// Used for the phone POS layout.
final class POSPortraitHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
