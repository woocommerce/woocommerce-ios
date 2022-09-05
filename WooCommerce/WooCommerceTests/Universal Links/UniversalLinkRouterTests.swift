@testable import WooCommerce
import XCTest

final class UniversalLinkRouterTests: XCTestCase {
    func test_handle_when_there_is_a_route_matching_then_calls_to_perform_action_with_right_actions() {
        // Given
        let path = "/test/path"
        let queryItem = URLQueryItem(name: "name", value: "value")
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = path
            components.queryItems = [
                queryItem
            ]

        var retrievedParameters: [String: String]?
        let route = MockRoute(path: path, performAction: { parameters in
            retrievedParameters = parameters

            return true
        })
        let sut = UniversalLinkRouter(routes: [route])

        guard let url = components.url else {
            XCTFail()
            return
        }

        // When
        sut.handle(url: url)

        // Then
        XCTAssertEqual(retrievedParameters?[queryItem.name], queryItem.value)
    }

    func test_handle_when_there_are_routes_matching_then_calls_to_perform_action_to_the_first_one() {
        // Given
        let path = "/test/path"
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = path

        var routeOneWasCalled = false
        let routeOne = MockRoute(path: path, performAction: { _ in
            routeOneWasCalled = true

            return true
        })

        var routeTwoWasCalled = false
        let routeTwo = MockRoute(path: path, performAction: { _ in
            routeTwoWasCalled = true

            return true
        })


        let sut = UniversalLinkRouter(routes: [routeOne, routeTwo])

        guard let url = components.url else {
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
        let url = URL(string: "woocommerce.com/a/nice/path")!

        var routeOneWasCalled = false
        let routeOne = MockRoute(path: "a/different/path", performAction: { _ in
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

    func test_handle_when_there_the_route_cannot_perform_the_action_then_bounces_url() {
        // Given
        let path = "/test/path"
        let queryItem = URLQueryItem(name: "name", value: "value")
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = path
            components.queryItems = [
                queryItem
            ]

        let route = MockRoute(path: path, performAction: { _ in
            return false
        })

        guard let url = components.url else {
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
}
