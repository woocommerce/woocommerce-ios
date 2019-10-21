import Yosemite

/// View model for an Order search result cell that encapsulates the necessary Order models.
struct OrderSearchCellViewModel {
    let orderDetailsViewModel: OrderDetailsViewModel
    let orderStatus: OrderStatus?
}
