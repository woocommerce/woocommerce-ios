import SwiftUI

/// Displays a collapsible customer card that shows customer details in the collapsed and expanded states.
struct CollapsibleCustomerCard: View {
    @ObservedObject private var viewModel: CollapsibleCustomerCardViewModel

    init(viewModel: CollapsibleCustomerCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        CollapsibleOrderFormCard(hasSubtleChevron: true,
                                 isCollapsed: $viewModel.isCollapsed,
                                 showsBorder: true,
                                 padding: Layout.headerAdditionalPadding,
                                 label: {
            CollapsibleCustomerCardHeaderView(isCollapsed: viewModel.isCollapsed,
                                              email: viewModel.email,
                                              emailPlaceholder: viewModel.emailPlaceholder,
                                              shippingAddress: viewModel.shippingAddress)
        }, content: {
            Text("Email address text field")
            Text("Create new customer toggle")
            Text("Customer address")
            Text("Remove customer from order")
        })
    }
}

private extension CollapsibleCustomerCard {
    enum Layout {
        static let headerAdditionalPadding: EdgeInsets = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
    }
}

struct CollapsibleCustomerCard_Previews: PreviewProvider {
    static var previews: some View {
        CollapsibleCustomerCard(viewModel: .init(customerData: .init(email: nil,
                                                                     fullName: nil,
                                                                     billingAddressFormatted: nil,
                                                                     shippingAddressFormatted: nil),
                                                 isCustomerAccountRequired: true,
                                                 isEditable: true,
                                                 isCollapsed: false))
    }
}
