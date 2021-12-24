import SwiftUI

/// Renders a product add-on
///
struct ProductAddOn: View {

    /// Representation of the view state.
    ///
    let viewModel: ProductAddOnViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Divider()

            // Add-on name
            Text(viewModel.name)
                .headlineStyle()
                .padding([.leading, .trailing])

            // Add-on description & price
            HStack(alignment: .bottom) {
                Text(viewModel.description)
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .renderedIf(viewModel.showDescription)

                Text(viewModel.price)
                    .secondaryBodyStyle()
                    .renderedIf(viewModel.showPrice)
            }
            .padding([.leading, .trailing])
            .renderedIf(viewModel.showPrice || viewModel.showDescription)

            Spacer()
                .frame(height: 1)

            // Add-on options
            ForEach(viewModel.options) { option in
                HStack(alignment: .bottom) {
                    Text(option.name)
                        .bodyStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(option.price)
                        .secondaryBodyStyle()
                        .renderedIf(option.showPrice)
                }
                .padding([.leading, .trailing])

                Divider()
                    .padding(option.offSetDivider ? [.leading] : [])
            }

            Divider()
                .renderedIf(viewModel.showBottomDivider)
        }
        .background(Color(.basicBackground))
    }
}

// MARK: Previews
struct ProductAddOn_Previews: PreviewProvider {

    static let toppingViewModel = ProductAddOnViewModel(name: "Pizza Topping",
                                                 description: "Select your topping",
                                                 price: "",
                                                 options: [
                                                    .init(name: "Peperoni", price: "$2.99", offSetDivider: true),
                                                    .init(name: "Salami", price: "$1.99", offSetDivider: true),
                                                    .init(name: "Ham", price: "$1.99", offSetDivider: false),
                                                 ])
    static let toppingViewModel2 = ProductAddOnViewModel(name: "Pizza Topping",
                                                 description: "",
                                                 price: "",
                                                 options: [
                                                    .init(name: "Peperoni", price: "$2.99", offSetDivider: true),
                                                    .init(name: "Salami", price: "$1.99", offSetDivider: true),
                                                    .init(name: "Ham", price: "$1.99", offSetDivider: false),
                                                 ])
    static let deliveryViewModel = ProductAddOnViewModel(name: "Delivery",
                                                 description: "Weather you need delivery or not",
                                                 price: "$6.00",
                                                 options: [])
    static let engravingViewModel = ProductAddOnViewModel(name: "Engraving",
                                                 description: "",
                                                 price: "$5.00",
                                                 options: [])

    static var previews: some View {
        Group {
            ProductAddOn(viewModel: deliveryViewModel)
                .environment(\.colorScheme, .light)
                .previewLayout(.fixed(width: 420, height: 100))

            ProductAddOn(viewModel: toppingViewModel)
                .environment(\.colorScheme, .light)
                .previewLayout(.fixed(width: 420, height: 220))

            ProductAddOn(viewModel: toppingViewModel2)
                .environment(\.colorScheme, .light)
                .previewLayout(.fixed(width: 420, height: 220))

            ProductAddOn(viewModel: engravingViewModel)
                .environment(\.colorScheme, .light)
                .previewLayout(.fixed(width: 420, height: 100))
        }
    }
}
