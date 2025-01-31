
import Foundation
import UIKit

@testable import WooCommerce

/// A mock `NoticePresenter` that just records the queued `Notice` instances.
///
final class MockNoticePresenter: NoticePresenter {
    var presentingViewController: UIViewController?

    private(set) var queuedNotices = [Notice]()
    var onNoticeQueued: (Notice) -> Void = { _ in }

    func enqueue(notice: Notice) -> Bool {
        queuedNotices.append(notice)
        onNoticeQueued(notice)
        return true
    }
}
