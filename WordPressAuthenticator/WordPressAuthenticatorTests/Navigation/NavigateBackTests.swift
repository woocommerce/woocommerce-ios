import XCTest
@testable import WordPressAuthenticator

final class NavigateBackTests: XCTestCase {

    func testNavigationCommandNavigatesToExpectedDestination() {
        let origin = UIViewController()
        let navigationController = MockNavigationController(rootViewController: origin)
        // UINavigationController automatically pushes the given rootViewController
        //navigationController.pushViewController(origin, animated: false)

        let command = NavigateBack()
        command.execute(from: origin)

        let navigationStackCount = navigationController.viewControllers.count

        XCTAssertEqual(navigationStackCount, 1)
    }
}
