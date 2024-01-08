import SwiftUI

/// View to set ad destination for a new Blaze campaign
struct BlazeAdDestinationSettingView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var viewModel: BlazeAdDestinationSettingViewModel

    init(viewModel: BlazeAdDestinationSettingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    sectionHeading(title: Localization.destinationUrlHeading)
                    destinationItem(title: Localization.productURLLabel,
                                    subtitle: String(format: Localization.destinationUrlSubtitle, viewModel.productURL),
                                    type: BlazeAdDestinationSettingViewModel.DestinationURLType.product,
                                    showBottomDivider: true)

                    destinationItem(title: Localization.siteHomeLabel,
                                    subtitle: String(format: Localization.destinationUrlSubtitle, viewModel.homeURL),
                                    type: BlazeAdDestinationSettingViewModel.DestinationURLType.home)
                }
                .padding(.bottom, Layout.sectionVerticalSpacing)

                VStack {
                    /// URL Parameters section
                    sectionHeading(title: Localization.urlParametersHeading)

                    VStack {
                        ForEach(viewModel.parameters, id: \.self) { parameter in
                            parameterItem(itemName: parameter.key)
                        }

                        Button(Localization.addParameterButton) {
                            // todo
                        }
                        .buttonStyle(PlusButtonStyle())
                        .padding([.leading, .trailing], Layout.contentSpacing)
                        .padding(.bottom, Layout.parametersVerticalSpacing)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))

                    VStack {
                        Text(viewModel.remainingCharactersLabel)
                            .padding(.bottom, Layout.contentVerticalSpacing)
                        Text(viewModel.finalDestinationLabel)
                    }
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing], Layout.contentSpacing)
                    .padding([.top, .bottom], Layout.contentVerticalSpacing)
                    .background(Color(.systemGray6))
                }
                Spacer()
            }
            .background(Color(.systemGray6))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.adDestination)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
    private func sectionHeading(title: String) -> some View {
        Text(title.uppercased())
            .subheadlineStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Layout.sectionHeadingPadding)
    }

    private func destinationItem(title: String,
                                 subtitle: String,
                                 type: BlazeAdDestinationSettingViewModel.DestinationURLType,
                                 showBottomDivider: Bool = false) -> some View {
        HStack(alignment: .center) {
            if type == viewModel.selectedDestinationType {
                Image(systemName: "checkmark")
                    .padding(.leading, Layout.contentSpacing)
                    .padding(.trailing, Layout.contentHorizontalSpacing)
                    .foregroundColor(Color(uiColor: .accent))
            } else {
                Image(systemName: "checkmark")
                    .padding(.leading, Layout.contentSpacing)
                    .padding(.trailing, Layout.contentHorizontalSpacing)
                    .hidden() // Small hack to make the icon space consistent while not showing the icon.
            }

            VStack(alignment: .leading) {
                Text(title)
                    .bodyStyle()
                    .padding(.top, Layout.contentVerticalSpacing)
                Text(subtitle)
                    .subheadlineStyle()
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, Layout.contentVerticalSpacing)

                if showBottomDivider {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .onTapGesture {
            viewModel.setDestinationType(type: type)
        }
    }

    private func parameterItem(itemName: String) -> some View {
        VStack {
            HStack {
                Text(itemName)
                    .padding([.top, .bottom], Layout.parametersVerticalSpacing)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.systemGray4))
                    .padding(.leading, 8)
                    .padding(.trailing, Layout.contentSpacing)
            }
            .padding(.leading, Layout.contentSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray6))
                .padding(.leading, Layout.contentSpacing)
        }
    }
}

private extension BlazeAdDestinationSettingView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let contentSpacing: CGFloat = 16
        static let contentVerticalSpacing: CGFloat = 8
        static let contentHorizontalSpacing: CGFloat = 8
        static let sectionVerticalSpacing: CGFloat = 24
        static let parametersVerticalSpacing: CGFloat = 11
        static let sectionHeadingPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 8, trailing: 16)
    }

    enum Localization {
        static let cancel = NSLocalizedString(
            "blazeAdDestinationSettingView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the Blaze Ad Destination setting screen"
        )
        static let adDestination = NSLocalizedString(
            "blazeAdDestinationSettingView.adDestination",
            value: "Ad Destination",
            comment: "Title of the Blaze Ad Destination setting screen."
        )

        static let destinationUrlHeading = NSLocalizedString(
            "blazeAdDestinationSettingView.destinationUrlHeading",
            value: "Destination URL",
            comment: "Heading for the destination URL section in Blaze Ad Destination screen.")

        static let productURLLabel = NSLocalizedString(
            "blazeAdDestinationSettingView.productURLLabel",
            value: "The Product URL",
            comment: "Label for the product URL destination option in Blaze Ad Destination screen."
        )

        static let siteHomeLabel = NSLocalizedString(
            "blazeAdDestinationSettingView.siteHomeLabel",
            value: "The site home",
            comment: "Label for the site home destination option in Blaze Ad Destination screen."
        )


        static let destinationUrlSubtitle = NSLocalizedString(
            "blazeAdDestinationSettingView.destinationUrlSubtitle",
            value: "It will link to: %1$@",
            comment: "Subtitle for each destination type showing the URL to link to. " +
            "%1$@ will be replaced by the URL."
        )

        static let urlParametersHeading = NSLocalizedString(
            "blazeAdDestinationSettingView.urlParametersHeading",
            value: "URL Parameters",
            comment: "Heading for the URL Parameters section in Blaze Ad Destination screen."
        )

        static let addParameterButton = NSLocalizedString(
            "blazeAdDestinationSettingView.addParameterButton",
            value: "Add parameter",
            comment: "Button to add a new URL parameter in Blaze Ad Destination screen."
        )
    }
}

struct BlazeAdDestinationSettingView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeAdDestinationSettingView(viewModel: .init(productURL: "https://woo.com/product", homeURL: "https://woo.com/"))
    }
}
