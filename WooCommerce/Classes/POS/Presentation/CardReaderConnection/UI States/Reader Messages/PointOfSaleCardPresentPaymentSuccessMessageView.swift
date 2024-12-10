import SwiftUI

struct PointOfSaleCardPresentPaymentSuccessMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State private var isShowingSendReceiptView: Bool = false
    @State private var isShowingReceiptNotEligibleBanner: Bool = false
    @State private var textFieldInput: String = ""

    var body: some View {
        if isShowingSendReceiptView {
            sendReceiptView
        } else {
            ZStack {
                VStack(alignment: .center, spacing: Constants.headerSpacing) {
                    successIcon
                        .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                        .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                    VStack(alignment: .center, spacing: Constants.textSpacing) {
                        Text(viewModel.title)
                            .font(.posTitleEmphasized)
                            .foregroundStyle(Color.posPrimaryText)
                            .accessibilityAddTraits(.isHeader)
                            .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                        if let message = viewModel.message {
                            Text(message)
                                .font(.posBodyRegular)
                                .foregroundStyle(Color.posPrimaryText)
                                .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
                        }
                    }
                    PaymentsActionButtons(isShowingSendReceiptView: $isShowingSendReceiptView,
                                          isShowingReceiptNotEligibleBanner: $isShowingReceiptNotEligibleBanner)
                        .matchedGeometryEffect(id: animation.actionButtonsTransitionId, in: animation.namespace, properties: .position)
                }
                .multilineTextAlignment(.center)

                if isShowingReceiptNotEligibleBanner {
                    VStack {
                        Spacer()
                        POSReceiptEligibilityBanner(isVisible: $isShowingReceiptNotEligibleBanner)
                            .transition(.move(edge: .bottom))
                            .padding(.bottom)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
    }

    private var sendReceiptView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button(action: {
                    isShowingSendReceiptView = false
                }, label: {
                    Image(systemName: "arrow.backward")
                        .font(.headline)
                        .foregroundColor(.primary)
                })
                Spacer()
            }
            .padding()

            Text(Localization.title)
                .font(.largeTitle)
                .bold()

            Text(Localization.subtitle)
                .font(.headline)

            TextField(Localization.textfieldPlaceholder, text: $textFieldInput)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
                .padding(.horizontal)

            Button(action: {
                Task { @MainActor in
                    // TODO: Access posmodel
                    // await posModel.sendReceipt(to: textFieldInput)
                }
            }, label: {
                HStack(spacing: Constants.buttonSpacing) {
                    Text(Localization.buttonTitle)
                        .font(Constants.buttonFont)
                }
            })
            .padding(Constants.buttonPadding)
            .foregroundColor(Color.posPrimaryTextInverted)
            .background(Color.posOverlayFillInverted)
            .cornerRadius(Constants.buttonCornerRadius)

            Spacer()
        }
        .padding()
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
                .shadow(color: Color(.wooCommerceEmerald(.shade80)).opacity(Constants.shadowOpacity),
                        radius: Constants.shadowRadius, x: Constants.shadowSize.width, y: Constants.shadowSize.height)
                .foregroundColor(circleBackgroundColor)
            Image(PointOfSaleAssets.successCheck.imageName)
                .renderingMode(.template)
                .foregroundColor(checkmarkColor)
                .frame(width: 52)
                .accessibilityHidden(true)
        }
    }

    private var circleBackgroundColor: Color {
        Color(red: 8/255, green: 251/255, blue: 135/255)
    }

    private var checkmarkColor: Color {
        Color.posSecondaryBackground
    }
}

private extension PointOfSaleCardPresentPaymentSuccessMessageView {
    enum Constants {
        static let imageName: String = "checkmark"
        static let imageSize: CGSize = .init(width: 165, height: 165)
        static let checkmarkSize: CGFloat = 56
        static let shadowOpacity: CGFloat = 0.16
        static let shadowRadius: CGFloat = 16
        static let shadowSize: CGSize = .init(width: 0, height: 8)
        static let headerSpacing: CGFloat = 56
        static let textSpacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
    }
}

private extension PointOfSaleCardPresentPaymentSuccessMessageView {
    struct Localization {
        static let title = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.title",
            value: "Receipt",
            comment: "Button title for the receipt button")
        static let subtitle = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.subtitle",
            value: "Email",
            comment: "Subtitle for the view where an email address should be entered when sending receipts")
        static let buttonTitle = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.button.title",
            value: "Send",
            comment: "Button title for sending a receipt")
        static let textfieldPlaceholder = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.textfield.placeholder",
            value: "Enter an email",
            comment: "Placeholder for the view where an email address should be entered when sending receipts")
    }
}

#Preview {
    @Namespace var namespace

    return PointOfSaleCardPresentPaymentSuccessMessageView(
        viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel(formattedOrderTotal: "$3.00"),
        animation: .init(namespace: namespace)
    )
}
