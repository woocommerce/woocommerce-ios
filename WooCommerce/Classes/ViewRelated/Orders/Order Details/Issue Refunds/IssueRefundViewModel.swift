import Foundation

/// ViewModel for presenting the issue refund screen to the user.
///
final class IssueRefundViewModel {

    /// Title for the navigation bar
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let title: String = "$35.45"

    /// String indicating how many items the user has selected to refund
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let selectedItemsTitle: String = "3 items selected"

    /// The sections and rows to display in the `UITableView`.
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let sections: [Section] = [
        Section(rows: [
            RefundItemViewModel(productImage: nil, productTitle: "Item 1", productQuantityAndPrice: "2 x $30.27 each", quantityToRefund: "1"),
            RefundItemViewModel(productImage: nil, productTitle: "Item 2", productQuantityAndPrice: "4 x $20.00 each", quantityToRefund: "2"),
            RefundItemViewModel(productImage: nil, productTitle: "Item 3", productQuantityAndPrice: "3 x $15.99 each", quantityToRefund: "0"),
            RefundProductsTotalViewModel(productsTax: "$13.45", productsSubtotal: "$66.26", productsTotal: "$79.71")
        ]),
        Section(rows: [
            ShippingSwitchViewModel(title: "Refund Shipping", isOn: true),
            RefundShippingDetailsViewModel(carrierRate: "USPS Flat Rate",
                                           carrierCost: "$10.0",
                                           shippingTax: "$2.99",
                                           shippingSubtotal: "$10.0",
                                           shippingTotal: "$12.99")
        ])
    ]
}

// MARK: Sections and Rows

/// Protocol that any `Section` item  should conform to.
///
protocol IssueRefundRow {}

extension IssueRefundViewModel {

    struct Section {
        let rows: [IssueRefundRow]
    }

    /// ViewModel that represents the shipping switch row.
    struct ShippingSwitchViewModel: IssueRefundRow {
        let title: String
        let isOn: Bool
    }
}

extension RefundItemViewModel: IssueRefundRow {}

extension RefundProductsTotalViewModel: IssueRefundRow {}

extension RefundShippingDetailsViewModel: IssueRefundRow {}
