import XCTest
@testable import WooCommerce
import Yosemite

final class WhatsNewFactoryTests: XCTestCase {

    func test_create_whats_new_view_controller_has_expected_properties() {
        // Arrange
        let announcement = Announcement.fake().copy(features: [Feature.fake()])

        // Act
        let viewController = WhatsNewFactory.whatsNew(announcement, onDismiss: {}) as? WhatsNewHostingController

        // Assert
        XCTAssertEqual(viewController?.rootView.viewModel.items.count, 1)
        XCTAssertEqual(viewController?.modalPresentationStyle, UIModalPresentationStyle.formSheet)
    }

    func test_announcement_with_iconUrl_contains_icon() {
        // Given
        let iconURL = "https://s0.wordpress.com/i/store/mobile/plans-premium.png"
        let announcement = Announcement.fake().copy(features: [Feature.fake().copy(iconUrl: iconURL)])

        // When
        let viewController = WhatsNewFactory.whatsNew(announcement, onDismiss: {}) as? WhatsNewHostingController
        let announcementIcon = viewController?.rootView.viewModel.items.first?.icon

        // Then
        XCTAssertNotNil(announcementIcon)
    }

    func test_announcement_with_iconBase64_contains_icon() {
        // Given
        // swiftlint:disable line_length
        let iconBase64String = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAYAAACM/rhtAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAPXSURBVHgBzZk9bNNAFMffOZ92EtHA0A5ITSkDCzSMSEhNBALBUhBiYaB0YaWdGJusSNB2YICFLGUssCCVpWFALEikG0i0GImhRYgU5cNO2/h4z/lQkjrJOQlJflLry/kl/ufvd+d3FwYdkslkIoyxsCRJ04BHzvkIvh6hc9jeY5KkgmGo2N40DCMZCASS0AHMTnAaRbh1/QEqmK+IsYHKAZL7APGgLKuibxISSMI8hcIiCYMegEITokLbCszm8/MYtNiBY+1QjWIx7vf7E62CWgrM6/pSr1xrhsH5sl9RFpqdtxRo3lJdf4XNCPQDxlIFjycaZGzvyCmreHTuMzoXhv6SVGQ52tgpNXaUb2u/xRERzPelxs46B7PZ7D3J4XgBAwRzcgFzcrnyuiowrWkhD8AGNkMwQGiS35fliUo+Vm+xyzBiMGBxBE1nLk1brL6mf2X3vsMQUfB6g+Si6WDZvaHCiQ8IOpoO5jWN3Au1esPaFw2+pYvQC6ZGXXD1lKdlDOWiT1GCTNO0CC8NjpZcWv0NvcLvZvDm9om2ccXDw6iEpVAEumTUJ9mKz+5zoTjmcIQlquWgC55dG4GXN47D8+v1tcTdcwo8vnwMuoFxHpGwsBwXCbZyaczngNPHnWZ7MuisxpC42bMKvNvWhT/LUqAkTUncMEIiweTSE3SE8qfCTq4IW+lDs03H3ZxRFffoYwbWtwt1n+FzMdNV+iwRzCodR7BYQpR5+ikHa1+1uj5ypJ044gqO3IcXAmAHe9mN5A6Ofh8rcVa30e+2fTmQaL4RDd7cPYAPP4860yiu2cChnKykhAikjTL8L/61LefvvP5jOtVOnNXAqbyPppf7b/dgzO+A1ZkgCKCS5ymRSCtxxMWT7rqcsxo4jexkBZ9InP9w0lIQx+UMdAg5YtVX61wXpCQHrgdEImunFxF6IA5owW9eNZfPp9stK9e3dNj8JZ7grZgMOuDWGbldmIprlImSQE2L0doXhgjUk5Blea5UsJaWmWkYIlDYBAo0RzFQ5YqLlRUYEsruqeV2CXNjCAvX/7DFYRcVRUUrAqvPHnIRq4c4DBgc+3G5ZlOp7uGoeL3Lg7zVdG2/LCdq+ywnN1wGbPB+7ctUlbAUGnS+sduyvNC93psgOIH3BM7fy7h5ZHXKUiDlI32bftxuuoaiKLSdbFlVtSzQcI9kHpN2Dpsq9Bgqpcr7MC33H4UesJiTIXwuxnCUz0IPINd8shxr5lottiqAGqHTYHMfxyyMGVuhmUJEWEcCa6EFf3lNHcYLh/A4XvszBFAhzHmKM5akignntiR0wD80jb4Ye7HEOwAAAABJRU5ErkJggg=="
        // swiftlint:enable line_length
        let announcement = Announcement.fake().copy(features: [Feature.fake().copy(iconBase64: iconBase64String)])

        // When
        let viewController = WhatsNewFactory.whatsNew(announcement, onDismiss: {}) as? WhatsNewHostingController
        let announcementIcon = viewController?.rootView.viewModel.items.first?.icon

        // Then
        XCTAssertNotNil(announcementIcon)
    }
}
