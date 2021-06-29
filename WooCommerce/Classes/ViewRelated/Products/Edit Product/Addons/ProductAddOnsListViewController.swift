import UIKit
import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps an `ProductAddOnsList` view.
///
final class ProductAddOnsListViewController: UIHostingController<ProductAddOnsList> {
    init(viewModel: ProductAddOnsListViewModel) {
        super.init(rootView: ProductAddOnsList(viewModel: viewModel))
        title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders a list of product add-ons
///
struct ProductAddOnsList: View {

    /// View model that directs the view content.
    ///
    let viewModel: ProductAddOnsListViewModel

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.addOns) { addOn in
                    ProductAddOn(viewModel: addOn)
                }
                AddOnListNotice(updateText: viewModel.infoNotice)
            }
        }
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}

/// Renders a info notice with an icon
///
private struct AddOnListNotice: View {

    /// Content to be rendered next to the info icon.
    ///
    let updateText: String

    var body: some View {
        HStack {
            Image(uiImage: .infoOutlineImage)
            Text(updateText)
        }
        .footnoteStyle()
        .padding([.leading, .trailing]).padding(.top, 4)
    }
}


// MARK: Previews
struct ProductAddOnsList_Previews: PreviewProvider {

    static let viewModel = ProductAddOnsListViewModel(addOns: [
        .init(name: "Toppings", description: "Select your toppings", price: "", options: [
            .init(name: "Pepperoni", price: "$2.99", offSetDivider: true),
            .init(name: "Salami", price: "$1.99", offSetDivider: true),
            .init(name: "Ham", price: "$1.99", offSetDivider: false),
        ]),
        .init(name: "Delivery", description: "Do you want it delivered to your address?", price: "$10.00", options: []),
        .init(name: "Engraving", description: "", price: "$10.00", options: []),
    ])

    static var previews: some View {
        ProductAddOnsList(viewModel: viewModel)
            .environment(\.colorScheme, .light)
    }
}
