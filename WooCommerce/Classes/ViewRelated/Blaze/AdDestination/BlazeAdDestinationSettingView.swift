import SwiftUI

/// View to set ad destination for a new Blaze campaign
struct BlazeAdDestinationSettingView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var viewModel: BlazeAdDestinationSettingViewModel

    typealias DestinationType = BlazeAdDestinationSettingViewModel.DestinationURLType

    init(viewModel: BlazeAdDestinationSettingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // URL destination section
                VStack(spacing: 0) {
                    sectionHeading(title: Localization.destinationUrlHeading)
                    destinationItem(title: Localization.productURLLabel,
                                    subtitle: String(format: Localization.destinationUrlSubtitle, viewModel.productURL),
                                    type: DestinationType.product,
                                    showBottomDivider: true)

                    destinationItem(title: Localization.siteHomeLabel,
                                    subtitle: String(format: Localization.destinationUrlSubtitle, viewModel.homeURL),
                                    type: DestinationType.home)
                }
                .padding(.bottom, Layout.sectionVerticalSpacing)

                // URL parameters section
                List {
                    Section {
                        ForEach(viewModel.parameters, id: \.self) { parameter in
                            parameterItem(itemName: parameter.key)
                        }
                        .onDelete(perform: deleteParameter)

                        Button(action: {
                            // todo
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text(Localization.addParameterButton)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.leading, Layout.contentSpacing)
                        .listRowSeparator(.hidden, edges: .bottom)

                    } header: {
                        Text(Localization.urlParametersHeading)
                    } footer: {
                        // Remaining characters and final destination
                        VStack(alignment: .leading) {
                            Text(viewModel.remainingCharactersLabel)
                                .subheadlineStyle()
                                .padding(.bottom, Layout.contentVerticalSpacing)

                            Text(viewModel.finalDestinationLabel)
                                .subheadlineStyle()
                        }
                        .padding(.vertical, Layout.contentVerticalSpacing)
                    }
                }
                .listStyle(.grouped)
            }
            .background(Color(.listBackground))
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
                                 type: DestinationType,
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
                        .background(Color(.systemGray3))
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
                Spacer()
                Image(systemName: "chevron.right")
                    .tint(.secondary)
                    .padding(.leading, Layout.contentHorizontalSpacing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func deleteParameter(at offsets: IndexSet) {
        viewModel.parameters.remove(atOffsets: offsets)
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
        BlazeAdDestinationSettingView(
            viewModel: .init(
                productURL: "https://woo.com/product",
                homeURL: "https://woo.com/",
                parameters: [
                    BlazeAdDestinationSettingViewModel.BlazeAdURLParameter(key: "key1", value: "value1"),
                    BlazeAdDestinationSettingViewModel.BlazeAdURLParameter(key: "key2", value: "value2"),
                    BlazeAdDestinationSettingViewModel.BlazeAdURLParameter(key: "key1", value: "value1")
                ]
            )
        )
    }
}
