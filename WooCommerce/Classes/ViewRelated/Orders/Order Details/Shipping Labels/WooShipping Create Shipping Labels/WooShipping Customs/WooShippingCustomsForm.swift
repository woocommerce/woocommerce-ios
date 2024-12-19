import SwiftUI

struct WooShippingCustomsForm: View {
    @State private var contentType: String = "Merchandise"
    @State private var restrictionType: String = "None"
    @State private var internationalTransactionNumber: String = ""
    @State private var returnToSender: Bool = false
    @State private var productDetails: [ProductDetail] = [
        ProductDetail(name: "Little Nap Brazil 250g", type: "Coffee beans", origin: "Japan", weight: 0.3, price: 20.0),
        ProductDetail(name: "Partners Brooklyn 250g", type: "", origin: "", weight: 0.0, price: 0.0)
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customs")) {
                    Picker("Content Type", selection: $contentType) {
                        Text("Merchandise").tag("Merchandise")
                        // Add more content types as needed
                    }
                    Picker("Restriction Type", selection: $restrictionType) {
                        Text("None").tag("None")
                        // Add more restriction types as needed
                    }
                    TextField("International Transaction Number", text: $internationalTransactionNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: false))
                    Toggle("Return to sender if package is not able to be delivered", isOn: $returnToSender)
                }

                //                Section(header: Text("Product Details")) {
                //                    ForEach($productDetails, id: \.$id) { $product in
                //                        VStack(alignment: .leading) {
                //                            Text(product.name)
                //                                .font(.headline)
                //                            Text("Type: \(product.type)")
                //                            Text("Origin: \(product.origin)")
                //                            Text("Weight: \(product.weight, specifier: "%.2f") kg")
                //                            Text("Price: $\(product.price, specifier: "%.2f")")
                //                        }
                //                        .padding(.vertical, 5)
                //                    }
            }

            Button(action: {
                // Action for adding missing information
            }) {
                Text("Add Missing Information")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Customs Form")
    }
}


struct ProductDetail: Identifiable {
    let id = UUID()
    var name: String
    var type: String
    var origin: String
    var weight: Double
    var price: Double
}
