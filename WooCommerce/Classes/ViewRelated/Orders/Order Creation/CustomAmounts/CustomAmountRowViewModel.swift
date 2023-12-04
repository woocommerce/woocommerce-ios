import Foundation

struct CustomAmountRowViewModel: Identifiable {
    let id: Int64
    let name: String
    let total: String
    let onEditCustomAmount: () -> Void
}
