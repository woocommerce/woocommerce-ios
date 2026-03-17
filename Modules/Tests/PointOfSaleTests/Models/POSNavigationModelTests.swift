import Testing
@testable import PointOfSale

@Suite("POSNavigationModel")
@MainActor
struct POSNavigationModelTests {

    @Test("initial state is sale tab, not showing checkout")
    func init_defaults_to_saleTab_and_not_showing_checkout() {
        // Given / When
        let sut = POSNavigationModel()

        // Then
        #expect(sut.selectedTab == .sale)
        #expect(sut.isShowingCheckout == false)
        #expect(sut.isShowingOrders == false)
        #expect(sut.isShowingBookings == false)
        #expect(sut.isShowingSettings == false)
    }

    @Test("showCheckout sets isShowingCheckout to true")
    func showCheckout_sets_isShowingCheckout_to_true() {
        // Given
        let sut = POSNavigationModel()

        // When
        sut.showCheckout()

        // Then
        #expect(sut.isShowingCheckout == true)
    }

    @Test("dismissCheckout sets isShowingCheckout to false")
    func dismissCheckout_sets_isShowingCheckout_to_false() {
        // Given
        let sut = POSNavigationModel()
        sut.showCheckout()

        // When
        sut.dismissCheckout()

        // Then
        #expect(sut.isShowingCheckout == false)
    }

    @Test("setting isShowingOrders selects orders tab")
    func isShowingOrders_selects_orders_tab() {
        // Given
        let sut = POSNavigationModel()

        // When
        sut.isShowingOrders = true

        // Then
        #expect(sut.selectedTab == .orders)
    }

    @Test("setting isShowingBookings selects bookings tab")
    func isShowingBookings_selects_bookings_tab() {
        // Given
        let sut = POSNavigationModel()

        // When
        sut.isShowingBookings = true

        // Then
        #expect(sut.selectedTab == .bookings)
    }

    @Test("setting isShowingSettings selects settings tab")
    func isShowingSettings_selects_settings_tab() {
        // Given
        let sut = POSNavigationModel()

        // When
        sut.isShowingSettings = true

        // Then
        #expect(sut.selectedTab == .settings)
    }

    @Test("startNewOrder dismisses checkout and returns to sale tab")
    func startNewOrder_dismisses_checkout_and_selects_sale_tab() {
        // Given
        let sut = POSNavigationModel()
        sut.selectedTab = .orders
        sut.showCheckout()

        // When
        sut.startNewOrder()

        // Then
        #expect(sut.isShowingCheckout == false)
        #expect(sut.selectedTab == .sale)
        #expect(sut.isShowingOrders == false)
        #expect(sut.isShowingBookings == false)
        #expect(sut.isShowingSettings == false)
    }
}
