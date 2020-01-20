import UIKit

/// Encapsulates context parameters to initiate a flow to pick media from several sources
///
struct MediaPickingContext {
    let origin: UIViewController
    let view: UIView

    init(origin: UIViewController, view: UIView) {
        self.origin = origin
        self.view = view
    }
}
