import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormInput: View {
    private let isCollasible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets
    @ObservedObject private var viewModel: ShippingLabelCustomsFormInputViewModel
    @State private var isCollapsed = false

    init(isCollasible: Bool, packageNumber: Int, safeAreaInsets: EdgeInsets, viewModel: ShippingLabelCustomsFormInputViewModel) {
        self.isCollasible = isCollasible
        self.packageNumber = packageNumber
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Constants.verticalPadding) {
            Button(action: {
                guard isCollasible else { return }
                isCollapsed.toggle()
            }, label: {
                HStack {
                    Text(String(format: Localization.packageNumber, packageNumber))
                        .font(.headline)
                    Text("-")
                        .font(.body)
                    Text("TODO: get package name")
                        .font(.body)
                    Spacer()
                    if isCollasible {
                        Image(uiImage: isCollapsed ? .chevronDownImage : .chevronUpImage)
                    }
                }
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.horizontal, insets: safeAreaInsets)

            Divider()
                .padding(.leading, Constants.horizontalPadding)

            Toggle(Localization.returnPolicyTitle, isOn: $viewModel.returnOnNonDelivery)
                .font(.body)
                .lineLimit(2)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.horizontal, insets: safeAreaInsets)
        }
        .padding(.vertical, Constants.verticalPadding)
        .background(Color(.listForeground))
    }
}

private extension ShippingLabelCustomsFormInput {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 13
    }
    enum Localization {
        static let packageNumber = NSLocalizedString("Package %1$d", comment: "Package index in Customs screen of Shipping Label flow")
        static let returnPolicyTitle = NSLocalizedString("Return to sender if package is unabled to be delivered",
                                                         comment: "Title for the return policy in Customs screen of Shipping Label flow")
    }
}

struct ShippingLabelCustomsFormInput_Previews: PreviewProvider {
    static let sampleViewModel: ShippingLabelCustomsFormInputViewModel = {
        let sampleOrder = ShippingLabelPackageDetailsViewModel.sampleOrder()
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", productIDs: sampleOrder.items.map { $0.productID })
        return .init(customsForm: sampleForm)
    }()

    static var previews: some View {
        ShippingLabelCustomsFormInput(isCollasible: true, packageNumber: 1, safeAreaInsets: .zero, viewModel: sampleViewModel)
    }
}
