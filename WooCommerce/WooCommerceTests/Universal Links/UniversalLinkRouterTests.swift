@testable import WooCommerce
import XCTest

final class UniversalLinkRouterTests: XCTestCase {
    func test_handle_when_there_is_a_route_matching_then_calls_to_perform_action_with_right_actions() {
        // Given
        let subPath = "/test/path"
        let queryItem = URLQueryItem(name: "name", value: "value")
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = "/mobile" + subPath
            components.queryItems = [
                queryItem
            ]

        var retrievedParameters: [String: String]?
        let route = MockRoute(subPath: subPath, performAction: { parameters in
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
        let subPath = "/test/path"
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = "/mobile" + subPath

        var routeOneWasCalled = false
        let routeOne = MockRoute(subPath: subPath, performAction: { _ in
            routeOneWasCalled = true

            return true
        })

        var routeTwoWasCalled = false
        let routeTwo = MockRoute(subPath: subPath, performAction: { _ in
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
        let url = URL(string: "woocommerce.com/mobile/a/nice/path")!

        var routeOneWasCalled = false
        let routeOne = MockRoute(subPath: "a/different/path", performAction: { _ in
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
        let queryItem = URLQueryItem(name: "name", value: "value")
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = subPath
            components.queryItems = [
                queryItem
            ]

        let route = MockRoute(subPath: subPath, performAction: { parameters in
            return true
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

    func test_handle_when_there_the_route_cannot_perform_the_action_then_bounces_url() {
        // Given
        let subPath = "/test/path"
        let queryItem = URLQueryItem(name: "name", value: "value")
        var components = URLComponents()
            components.scheme = "https"
            components.host = "woocommerce.com"
            components.path = "/mobile" + subPath
            components.queryItems = [
                queryItem
            ]

        let route = MockRoute(subPath: subPath, performAction: { _ in
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
