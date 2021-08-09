import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormInput: View {
    private let isCollapsible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets
    @ObservedObject private var viewModel: ShippingLabelCustomsFormInputViewModel
    @State private var isCollapsed = false

    init(isCollapsible: Bool, packageNumber: Int, safeAreaInsets: EdgeInsets, viewModel: ShippingLabelCustomsFormInputViewModel) {
        self.isCollapsible = isCollapsible
        self.packageNumber = packageNumber
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Constants.verticalPadding) {
            Button(action: {
                guard isCollapsible else { return }
                withAnimation {
                    isCollapsed.toggle()
                }
            }, label: {
                HStack {
                    Text(String(format: Localization.packageNumber, packageNumber))
                        .font(.headline)
                    Text("-")
                        .font(.body)
                    Text(viewModel.customsForm.packageName)
                        .font(.body)
                    Spacer()
                    if isCollapsible {
                        Image(uiImage: isCollapsed ? .chevronDownImage : .chevronUpImage)
                    }
                }
            })
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.horizontal, insets: safeAreaInsets)

            Divider()

            if !isCollapsed {
                Toggle(Localization.returnPolicyTitle, isOn: $viewModel.returnOnNonDelivery)
                    .font(.body)
                    .lineLimit(2)
                    .padding(.bottom, Constants.verticalPadding)
                    .padding(.horizontal, Constants.horizontalPadding)
                    .padding(.horizontal, insets: safeAreaInsets)
            }
        }
        .padding(.top, Constants.verticalPadding)
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
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", packageName: "Food Package", productIDs: sampleOrder.items.map { $0.productID })
        return .init(customsForm: sampleForm)
    }()

    static var previews: some View {
        ShippingLabelCustomsFormInput(isCollapsible: true, packageNumber: 1, safeAreaInsets: .zero, viewModel: sampleViewModel)
    }
}
