
import Foundation
import UIKit

@testable import WooCommerce

/// A mock `NoticePresenter` that just records the queued `Notice` instances.
///
final class MockNoticePresenter: NoticePresenter {
    var presentingViewController: UIViewController?

    private(set) var queuedNotices = [Notice]()

    func enqueue(notice: Notice) {
        queuedNotices.append(notice)
    }
}
