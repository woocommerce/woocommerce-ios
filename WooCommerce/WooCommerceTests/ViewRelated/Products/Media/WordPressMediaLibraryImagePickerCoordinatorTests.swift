import TestKit
import XCTest

@testable import WooCommerce

final class WordPressMediaLibraryImagePickerCoordinatorTests: XCTestCase {
    typealias Completion = WordPressMediaLibraryImagePickerCoordinator.Completion

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
        assertThat(sourceViewController.presentedViewController, isAnInstanceOf: WordPressMediaLibraryImagePickerViewController.self)
    }

    func test_mediaPicker_is_dismissed_after_didFinishPicking() throws {
        // Given
        let coordinator = makeCoordinator { _ in }

        // When
        coordinator.start(from: sourceViewController)
        waitUntil {
            self.sourceViewController.presentedViewController != nil
        }
        let mediaPicker = try XCTUnwrap(sourceViewController.presentedViewController as? WordPressMediaLibraryImagePickerViewController)
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
        let mediaPicker = try XCTUnwrap(sourceViewController.presentedViewController as? WordPressMediaLibraryImagePickerViewController)
        mediaPicker.mediaPickerControllerDidCancel(.init())

        // Then
        waitUntil {
            self.sourceViewController.presentedViewController == nil
        }
    }
}

private extension WordPressMediaLibraryImagePickerCoordinatorTests {
    func makeCoordinator(onCompletion: @escaping Completion) -> WordPressMediaLibraryImagePickerCoordinator {
        .init(siteID: 304, allowsMultipleImages: false, onCompletion: onCompletion)
    }
}
