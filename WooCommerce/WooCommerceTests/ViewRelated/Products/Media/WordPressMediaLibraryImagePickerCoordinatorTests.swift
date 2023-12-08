import TestKit
import XCTest
import Yosemite

@testable import WooCommerce

final class WordPressMediaLibraryImagePickerCoordinatorTests: XCTestCase {
    typealias Completion = WordPressMediaLibraryPickerCoordinator.Completion

    private var sourceViewController: UIViewController!

    override func setUp() {
        super.setUp()
        sourceViewController = UIViewController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        window.rootViewController = sourceViewController
    }

    override func tearDown() {
        sourceViewController = nil
        super.tearDown()
    }

    func test_start_presents_WordPressMediaLibraryImagePickerViewController() {
        // Given
        let coordinator = makeCoordinator { _ in }

        // When
        coordinator.start(from: sourceViewController)
        waitUntil {
            self.sourceViewController.presentedViewController != nil
        }

        // Then
        assertThat(sourceViewController.presentedViewController, isAnInstanceOf: WordPressMediaLibraryPickerViewController.self)
    }

    func test_mediaPicker_is_dismissed_after_didFinishPicking() throws {
        // Given
        let coordinator = makeCoordinator { _ in }

        // When
        coordinator.start(from: sourceViewController)
        waitUntil {
            self.sourceViewController.presentedViewController != nil
        }
        let mediaPicker = try XCTUnwrap(sourceViewController.presentedViewController as? WordPressMediaLibraryPickerViewController)
        mediaPicker.mediaPickerController(.init(), didFinishPicking: [])

        // Then
        waitUntil {
            self.sourceViewController.presentedViewController == nil
        }
    }

    func test_mediaPicker_is_dismissed_after_mediaPickerControllerDidCancel() throws {
        // Given
        let coordinator = makeCoordinator { _ in }

        // When
        coordinator.start(from: sourceViewController)
        waitUntil {
            self.sourceViewController.presentedViewController != nil
        }
        let mediaPicker = try XCTUnwrap(sourceViewController.presentedViewController as? WordPressMediaLibraryPickerViewController)
        mediaPicker.mediaPickerControllerDidCancel(.init())

        // Then
        waitUntil {
            self.sourceViewController.presentedViewController == nil
        }
    }

    /// Since `presentationControllerDidDismiss` is triggered after the view controller is dismissed, it verifies that the coordinator does not
    /// dismiss the modal again.
    func test_mediaPicker_is_not_dismissed_when_presentationControllerDidDismiss_is_invoked() throws {
        // Given
        let coordinator = makeCoordinator { _ in }

        // When
        coordinator.start(from: sourceViewController)
        waitUntil {
            self.sourceViewController.presentedViewController != nil
        }
        let mediaPicker = try XCTUnwrap(sourceViewController.presentedViewController as? WordPressMediaLibraryPickerViewController)
        mediaPicker.presentationController?.delegate?.presentationControllerDidDismiss?(.init(presentedViewController: .init(), presenting: nil))

        // Then
        waitUntil {
            self.sourceViewController.presentedViewController != nil
        }
    }

    // MARK: - `onCompletion`

    func test_media_items_are_returned_after_didFinishPicking() throws {
        let expectedMediaItems: [Media] = [.fake().copy(mediaID: 6), .fake().copy(mediaID: 12)]
        let mediaItems: [Media] = try waitFor { promise in
            // Given
            let coordinator = self.makeCoordinator { mediaItems in
                promise(mediaItems)
            }

            // When
            coordinator.start(from: self.sourceViewController)
            self.waitUntil {
                self.sourceViewController.presentedViewController != nil
            }
            let mediaPicker = try XCTUnwrap(self.sourceViewController.presentedViewController as? WordPressMediaLibraryPickerViewController)
            mediaPicker.mediaPickerController(.init(),
                                              didFinishPicking: expectedMediaItems.map { CancellableMedia(media: $0) })
            self.waitUntil {
                self.sourceViewController.presentedViewController == nil
            }
        }

        // Then
        XCTAssertEqual(mediaItems, expectedMediaItems)
    }

    func test_empty_media_items_are_returned_after_mediaPickerControllerDidCancel() throws {
        let mediaItems: [Media] = try waitFor { promise in
            // Given
            let coordinator = self.makeCoordinator { mediaItems in
                promise(mediaItems)
            }

            // When
            coordinator.start(from: self.sourceViewController)
            self.waitUntil {
                self.sourceViewController.presentedViewController != nil
            }
            let mediaPicker = try XCTUnwrap(self.sourceViewController.presentedViewController as? WordPressMediaLibraryPickerViewController)
            mediaPicker.mediaPickerControllerDidCancel(.init())
            self.waitUntil {
                self.sourceViewController.presentedViewController == nil
            }
        }

        // Then
        XCTAssertEqual(mediaItems, [])
    }

    /// Since `presentationControllerDidDismiss` is triggered after the view controller is dismissed, it verifies that the coordinator does not
    /// dismiss the modal again.
    func test_empty_media_items_are_returned_when_presentationControllerDidDismiss_is_invoked() throws {
        let mediaItems: [Media] = try waitFor { promise in
            // Given
            let coordinator = self.makeCoordinator { mediaItems in
                promise(mediaItems)
            }

            // When
            coordinator.start(from: self.sourceViewController)
            self.waitUntil {
                self.sourceViewController.presentedViewController != nil
            }
            let mediaPicker = try XCTUnwrap(self.sourceViewController.presentedViewController as? WordPressMediaLibraryPickerViewController)
            mediaPicker.presentationController?.delegate?.presentationControllerDidDismiss?(.init(presentedViewController: .init(), presenting: nil))
        }

        // Then
        XCTAssertEqual(mediaItems, [])
    }
}

private extension WordPressMediaLibraryImagePickerCoordinatorTests {
    func makeCoordinator(onCompletion: @escaping Completion) -> WordPressMediaLibraryPickerCoordinator {
        .init(siteID: 304, imagesOnly: true, allowsMultipleSelections: false, onCompletion: onCompletion)
    }
}
