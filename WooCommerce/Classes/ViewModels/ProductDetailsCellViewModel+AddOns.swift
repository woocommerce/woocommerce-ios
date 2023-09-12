import struct Yosemite.OrderItemProductAddOn

extension ProductDetailsCellViewModel {
    /// View model for the product add-ons in order details.
    /// Add-ons with the same key are aggregated to the same entry in the UI.
    struct AddOnsViewModel {
        let addOns: [AddOnViewModel]

        init(addOns: [OrderItemProductAddOn]) {
            let keyAndValues: [(key: String, values: [String])] = addOns.reduce([]) { partialResult, addOn in
                var newResult = partialResult
                if let index = partialResult.firstIndex(where: { $0.key == addOn.key }) {
                    newResult[index].values.append(addOn.value)
                } else {
                    newResult.append((key: addOn.key, values: [addOn.value]))
                }
                return newResult
            }
            self.addOns = keyAndValues.map { .init(key: $0.key, value: $0.values.joined(separator: "・")) }
        }
    }

    /// View model for a single product add-on in order details.
    struct AddOnViewModel: Equatable {
        let key: String
        let value: String
    }
}
