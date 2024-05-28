import Foundation

struct CartProduct: Equatable {
    let id: UUID
    let cartItemID: Int64?
    let product: POSProduct
    let quantity: Int
}
