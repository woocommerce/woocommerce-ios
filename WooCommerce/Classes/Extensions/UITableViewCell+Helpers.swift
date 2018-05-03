import UIKit

extension OrderDetailsSummaryCell {
    func configure(with viewModel: OrderDetailsSummaryViewModel) {
        title = viewModel.title
        dateCreated = viewModel.dateCreated
        paymentStatus = viewModel.paymentStatus
    }
}
