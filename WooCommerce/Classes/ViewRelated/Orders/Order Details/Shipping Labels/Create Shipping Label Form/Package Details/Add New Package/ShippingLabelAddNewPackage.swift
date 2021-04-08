import SwiftUI

struct ShippingLabelAddNewPackage: View {
    @State private var selectedIndex = 0

    var body: some View {
        Picker("Hello", selection: $selectedIndex) {
            Text("Custom Package")
            Text("Service Package")
        }.pickerStyle(SegmentedPickerStyle())
    }
}

struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelAddNewPackage()
    }
}
