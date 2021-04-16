import UIKit
import SwiftUI
import Yosemite

/// Hosting controller that wraps an `AddOnsListView`
///
final class OrderAddOnsListViewController: UIHostingController<OrderAddOnListI1View> {
    init(viewModel: OrderAddOnListI1ViewModel) {
        super.init(rootView: OrderAddOnListI1View(viewModel: viewModel))
        self.title = viewModel.title
        addCloseNavigationBarButton()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Renders a list of add ons
///
struct OrderAddOnListI1View: View {

    /// Static view model to populate the view content
    let viewModel: OrderAddOnListI1ViewModel

    /// Discussion: Due to the inability of customizing the `List` separators. We have opted to simulate the list behaviour with a `ScrollView` + `VStack`.
    /// We expect performance to be acceptable as normally an order does not have too many add-ons.
    /// A future improvement can be to use a `LazyVStack` when iOS-14 becomes our minimum target.
    ///
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.addOns) { addOn in
                    OrderAddOnI1View(viewModel: addOn)
                }
            }
        }
        .background(Color(.listBackground))
    }
}

/// Renders a single order add-on
///
struct OrderAddOnI1View: View {

    /// Static view model to populate the view content
    ///
    let viewModel: OrderAddOnI1ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text(viewModel.title)
                .headlineStyle()
                .padding([.leading, .trailing])

            HStack(alignment: .bottom) {
                Text(viewModel.content)
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(viewModel.price)
                    .secondaryBodyStyle()
            }
            .padding([.leading, .trailing])

            Divider()
        }
        .background(Color(.basicBackground))
    }
}

#if DEBUG

struct OrderAddOnView_Previews: PreviewProvider {
    static var previews: some View {
        OrderAddOnListI1View(viewModel: .init(addOns: [
            OrderAddOnI1ViewModel(id: 1, title: "Topping", content: "Pepperoni", price: "$3.00"),
            OrderAddOnI1ViewModel(id: 2, title: "Topping", content: "Salami", price: "$2.00"),
            OrderAddOnI1ViewModel(id: 3, title: "Soda", content: "3", price: "$6.00"),
            OrderAddOnI1ViewModel(id: 4, title: "Instructions", content: "Leave it in the front door", price: "")
        ]))
        .environment(\.colorScheme, .light)
    }
}

#endif
