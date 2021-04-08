import SwiftUI

struct ShippingLabelAddNewPackage: View {
    @Binding private var selectedIndex: Int

    var body: some View {
        VStack(spacing: 0) {
            SegmentedView(selection: $selectedIndex, views: [Text(Localization.customPackage), Text(Localization.servicePackage)])
                .frame(height: 44)
            Divider()
            ScrollView {

            }
        }

    }

    init() {
        _selectedIndex = .constant(0)
    }
}

private extension ShippingLabelAddNewPackage {
    enum Localization {
        static let customPackage = NSLocalizedString("Custom Package", comment: "Custom Package menu in Shipping Label Add New Package flow")
        static let servicePackage = NSLocalizedString("Service Package", comment: "Service Package menu in Shipping Label Add New Package flow")
    }
}

struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelAddNewPackage()
    }
}
