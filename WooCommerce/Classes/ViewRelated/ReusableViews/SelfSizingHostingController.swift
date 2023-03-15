import Foundation
import SwiftUI

/// Allows the hosting view to fit to its SwiftUI view's content size.
class SelfSizingHostingController<Content: View>: UIHostingController<Content> {
    override init(rootView: Content) {
        super.init(rootView: rootView)
        if #available(iOS 16.0, *) {
            sizingOptions =  [.intrinsicContentSize]
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
