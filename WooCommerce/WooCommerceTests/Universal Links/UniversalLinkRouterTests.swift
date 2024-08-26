@testable import WooCommerce
import XCTest

final class UniversalLinkRouterTests: XCTestCase {
    func test_handle_when_there_is_a_route_matching_then_calls_to_perform_action_with_right_actions() {
        // Given
        let subPath = "test/path"
        let queryItem = URLQueryItem(name: "name", value: "value")

        var retrievedParameters: [String: String]?
        let route = MockRoute(handledSubpaths: [subPath], performAction: { _, parameters in
            retrievedParameters = parameters

            return true
        })
        let sut = UniversalLinkRouter(routes: [route])

        guard let url = makeUrlForTesting(subPath: subPath, queryItem: queryItem) else {
            XCTFail()
            return
        }

        // When
        sut.handle(url: url)

        // Then
        XCTAssertEqual(retrievedParameters?[queryItem.name], queryItem.value)
    }

    func test_handle_when_there_is_a_route_matching_then_calls_to_perform_action_with_subpath() {
        // Given
        let subPath = "test/path/more/parts"

        var retrievedSubPath: String?
        let route = MockRoute(handledSubpaths: [subPath], performAction: { subPath, _ in
            retrievedSubPath = subPath

            return true
        })
        let sut = UniversalLinkRouter(routes: [route])

        guard let url = makeUrlForTesting(subPath: subPath) else {
            XCTFail()
            return
        }

        // When
        sut.handle(url: url)

        // Then
        XCTAssertEqual(retrievedSubPath, subPath)
    }

    func test_handle_when_there_are_routes_matching_then_calls_to_perform_action_to_the_first_one() {
        // Given
        let subPath = "test/path"

        var routeOneWasCalled = false
        let routeOne = MockRoute(handledSubpaths: [subPath], performAction: { _, _ in
            routeOneWasCalled = true

            return true
        })

        var routeTwoWasCalled = false
        let routeTwo = MockRoute(handledSubpaths: [subPath], performAction: { _, _ in
            routeTwoWasCalled = true

            return true
        })

        let sut = UniversalLinkRouter(routes: [routeOne, routeTwo])

        guard let url = makeUrlForTesting(subPath: subPath) else {
            XCTFail()
            return
        }

        // When
        sut.handle(url: url)

        // Then
        XCTAssertTrue(routeOneWasCalled)
        XCTAssertFalse(routeTwoWasCalled)
    }

    func test_handle_when_there_no_routes_matching_then_bounces_url() {
        // Given
        let url = URL(string: "woocommerce.com/mobile/a/nice/path")!

        var routeOneWasCalled = false
        let routeOne = MockRoute(handledSubpaths: ["a/different/path"], performAction: { _, _ in
            routeOneWasCalled = true

            return true
        })

        var bouncingURL = url
        let urlOpener = MockURLOpener(open: { url in
            bouncingURL = url
        })
        let sut = UniversalLinkRouter(routes: [routeOne], bouncingURLOpener: urlOpener)

        // When
        sut.handle(url: url)

        // Then
        XCTAssertEqual(bouncingURL, url)
        XCTAssertFalse(routeOneWasCalled)
    }

    func test_handle_when_the_link_does_not_have_mobile_segment_in_path_then_bounces_url() {
        // Given
        let subPath = "/test/path"

        let route = MockRoute(handledSubpaths: [subPath], performAction: { _, parameters in
            return true
        })

        guard let url = makeUrlForTesting(subPath: subPath, includeMobileSegment: false) else {
            XCTFail()
            return
        }

        var bouncingURL: URL?
        let urlOpener = MockURLOpener(open: { url in
            bouncingURL = url
        })
        let sut = UniversalLinkRouter(routes: [route], bouncingURLOpener: urlOpener)

        // When
        sut.handle(url: url)

        // Then
        XCTAssertEqual(bouncingURL, url)
    }

    func test_handle_when_there_the_route_cannot_perform_the_action_then_bounces_url() {
        // Given
        let subPath = "/test/path"

        let route = MockRoute(handledSubpaths: [subPath], performAction: { _, _ in
            return false
        })

        guard let url = makeUrlForTesting(subPath: subPath, includeMobileSegment: false) else {
            XCTFail()
            return
        }

        var bouncingURL: URL?
        let urlOpener = MockURLOpener(open: { url in
            bouncingURL = url
        })
        let sut = UniversalLinkRouter(routes: [route], bouncingURLOpener: urlOpener)

        // When
        sut.handle(url: url)

        // Then
        XCTAssertEqual(bouncingURL, url)
    }

    func test_defaultUniversalLinkRouter_includes_expected_routes() {
        // Given
        let mockNavigator = MockDeepLinkNavigator()

        // When
        let routes = UniversalLinkRouter.defaultRoutes(navigator: mockNavigator)

        // Then
        assertEqual(4, routes.count)

        XCTAssert(routes.contains { $0 is OrderDetailsRoute })
        XCTAssert(routes.contains { $0 is MyStoreRoute })
        XCTAssert(routes.contains { $0 is PaymentsRoute })
        XCTAssert(routes.contains { $0 is OrdersRoute })
    }
}

private extension UniversalLinkRouterTests {
    func makeUrlForTesting(subPath: String, queryItem: URLQueryItem? = nil, includeMobileSegment: Bool = true) -> URL? {
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
        if includeMobileSegment {
            components.path = "/mobile/" + subPath
        } else {
            components.path = subPath
        }
        if let queryItem = queryItem {
            components.queryItems = [
                queryItem
            ]
        }

        return components.url
    }
}
