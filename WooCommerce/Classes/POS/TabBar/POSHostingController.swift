import SwiftUI
import UIKit

/// A hosting controller for POS that locks orientation based on device type.
/// Phone: portrait only. iPad: landscape only.
final class POSHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .landscape
    }
}
