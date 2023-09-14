import SwiftUI
import WooFoundation

struct ProductCardSimplified: View {
    @State var productName: String
    @State var quantity: Int
    @State var productPrice: String
    @State var lineTotal: String

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: ProductCardLayout.standardWhitespace) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 40))

                VStack(alignment: .leading) {
                    Text(productName)
                        .bodyStyle()
                    ProductCardLinePriceSummary(quantity: quantity,
                                                productPrice: productPrice,
                                                lineTotal: lineTotal)
                }
            }
            .padding(ProductCardLayout.standardWhitespace)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: ProductCardLayout.frameCornerRadius)
                    .inset(by: 0.25)
                    .stroke(Color(uiColor: .separator),
                            lineWidth: ProductCardLayout.borderLineWidth)
            }
            .cornerRadius(ProductCardLayout.frameCornerRadius)
        }
        .padding(ProductCardLayout.standardWhitespace)
    }
}

struct ProductCardLinePriceSummary: View {
    @State var quantity: Int
    @State var productPrice: String
    @State var lineTotal: String
    var body: some View {
        HStack(spacing: ProductCardLayout.standardWhitespace) {
            HStack(spacing: ProductCardLayout.textComponentSpacing) {
//                Text(String(quantity)) + Text(" × ") + Text(productPrice)
                Text(String(quantity))
                Text("×")
                Text(productPrice)
                Spacer()
            }
            .subheadlineStyle()
            Text(lineTotal)
                .font(.subheadline)
        }
    }
}

enum ProductCardLayout {
    static let standardWhitespace: CGFloat = 16
    static let frameCornerRadius: CGFloat = 4
    static let textComponentSpacing: CGFloat = 4
    static let borderLineWidth: CGFloat = 0.5
}

struct ProductCardSimplified_Previews: PreviewProvider {
    static var previews: some View {
        ProductCardSimplified(productName: "Product name",
                              quantity: 3,
                              productPrice: "$15.00",
                              lineTotal: "$45.00")
        .previewLayout(.sizeThatFits)
    }
}
