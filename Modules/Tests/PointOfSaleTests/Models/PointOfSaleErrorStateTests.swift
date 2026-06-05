import Testing
@testable import PointOfSale

struct PointOfSaleErrorStateTests {
    @Test
    func errorOnLoadingOrders_uses_try_again_button_text() {
        let errorState = PointOfSaleErrorState.errorOnLoadingOrders()

        #expect(errorState.buttonText == "Try again")
    }

    @Test
    func errorOnLoadingOrdersNextPage_uses_try_again_button_text() {
        let errorState = PointOfSaleErrorState.errorOnLoadingOrdersNextPage()

        #expect(errorState.buttonText == "Try again")
    }

    @Test
    func errorOnLoadingProducts_keeps_generic_retry_button_text() {
        let errorState = PointOfSaleErrorState.errorOnLoadingProducts()

        #expect(errorState.buttonText == "Retry")
    }
}
