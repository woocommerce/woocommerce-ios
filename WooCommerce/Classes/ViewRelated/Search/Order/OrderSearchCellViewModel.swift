import Yosemite

/// View model for an Order search result cell that encapsulates the necessary Order models.
struct OrderSearchCellViewModel {
    let orderCellViewModel: OrderListCellViewModel
    let orderStatus: OrderStatus?
}
