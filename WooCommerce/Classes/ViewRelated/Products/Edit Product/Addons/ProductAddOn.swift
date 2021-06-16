import SwiftUI

/// Renders a product add-on
///
struct ProductAddOn: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            //Text(viewModel.title)
            Text("Add-on")
                .headlineStyle()
                .padding([.leading, .trailing])

            HStack(alignment: .bottom) {
                //Text(viewModel.content)
                Text("Description")
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

                //Text(viewModel.price)
                Text("$5.0")
                    .secondaryBodyStyle()
            }
            .padding([.leading, .trailing])

            Divider()
        }
        .background(Color(.basicBackground))
    }
}

// MARK: Previews
struct ProductAddOn_Previews: PreviewProvider {
    static var previews: some View {
        ProductAddOn()
            .environment(\.colorScheme, .light)
    }
}
