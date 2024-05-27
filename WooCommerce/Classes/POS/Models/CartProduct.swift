import Foundation

struct CartProduct {
    let id: UUID
    let cartItemID: Int64?
    let product: POSProduct
    let quantity: Int
}
