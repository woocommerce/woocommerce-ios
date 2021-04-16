import SwiftUI

struct ShippingLabelAddNewPackage: View {
    @ObservedObject private var viewModel = ShippingLabelAddNewPackageViewModel()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SegmentedView(selection: $viewModel.selectedIndex, views: [Text(Localization.customPackage), Text(Localization.servicePackage)])
                    .frame(height: 44)
                Divider()
            }.hidden()
            ScrollView {
            }
        }
        .navigationBarTitle(Text(Localization.title), displayMode: .inline)
    }
}

private extension ShippingLabelAddNewPackage {
    enum Localization {
        static let title = NSLocalizedString("Add New Package", comment: "Add New Package screen title in Shipping Label flow")
        static let customPackage = NSLocalizedString("Custom Package", comment: "Custom Package menu in Shipping Label Add New Package flow")
        static let servicePackage = NSLocalizedString("Service Package", comment: "Service Package menu in Shipping Label Add New Package flow")
    }
}

struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelAddNewPackage()
    }
}
