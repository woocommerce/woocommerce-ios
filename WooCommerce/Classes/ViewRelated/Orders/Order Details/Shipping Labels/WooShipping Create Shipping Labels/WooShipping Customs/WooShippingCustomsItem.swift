import SwiftUI
import WooFoundation

struct WooShippingCustomsItem: View {
    /// Whether the item list is collapsed
    @State private var isCollapsed: Bool = true
    @ObservedObject var viewModel: WooShippingCustomsItemViewModel
    @State private var isShowingHSTarrifInfoWebView = false
    @State private var isShowingCountries = false

    var body: some View {
        CollapsibleView(isCollapsed: $isCollapsed,
                        shouldShowDividers: false,
                        backgroundColor: .clear,
                        label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Little Nap Brazil 250g")
                        .headlineStyle()
                    Spacer()
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.withColorStudio(name: .red, shade: .shade60))
                        .renderedIf(viewModel.informationIsMissing)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Coffee beans")
                        Spacer()
                        Text("HS 14-1")
                    }

                    HStack {
                        Text("Japan")
                        Spacer()
                        Text("0.3kg")
                        Text("•")
                        Text("$20.00")
                    }
                }.renderedIf(isCollapsed)
                    .foregroundColor(.primary)
                    .subheadlineStyle()
                    .padding(.trailing, -30)
            }
            .padding(.top, 4)
        }, content: {
            VStack(alignment: .leading, spacing: 8) {
                Divider()

                Text("Description")
                    .foregroundColor(.primary)
                    .subheadlineStyle()
                    .padding(.top, 4)
                TextField("", text: $viewModel.description)
                    .padding(16)
                    .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
                Text("HS tarriff number")
                    .foregroundColor(.primary)
                    .subheadlineStyle()
                TextField("Optional", text: $viewModel.hsTariffNumber)
                    .padding(16)
                    .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
                Button {
                    isShowingHSTarrifInfoWebView = true
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                        Text("More info about HS tarriff")
                    }
                    .foregroundColor(Color(.wooCommercePurple(.shade60)))
                    .footnoteStyle()
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Value per unit")
                            .foregroundColor(.primary)
                            .subheadlineStyle()
                        TextField("$ 0", text: $viewModel.valuePerUnit)
                            .padding(16)
                            .roundedBorder(cornerRadius: 8,
                                           lineColor: viewModel.valuePerUnit.isEmpty ? .withColorStudio(name: .red, shade: .shade60) : Color(.separator),
                                           lineWidth: 1)
                        Text("Value required")
                            .foregroundColor(.withColorStudio(name: .red, shade: .shade60))
                            .footnoteStyle()
                            .renderedIf(viewModel.valuePerUnit.isEmpty)
                    }

                    VStack(alignment: .leading) {
                        Text("Weight per unit")
                            .foregroundColor(.primary)
                            .subheadlineStyle()
                        HStack {
                            TextField("0", text: $viewModel.weightPerUnit)
                                .padding(16)
                            Text("kg")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 8)
                        }
                        .roundedBorder(cornerRadius: 8,
                                       lineColor: viewModel.weightPerUnit.isEmpty ? .withColorStudio(name: .red, shade: .shade60) : Color(.separator),
                                       lineWidth: 1)
                        Text("Value required")
                            .foregroundColor(.withColorStudio(name: .red, shade: .shade60))
                            .footnoteStyle()
                            .renderedIf(viewModel.weightPerUnit.isEmpty)
                    }
                }

                Text("Origin Country")
                    .foregroundColor(.primary)
                    .subheadlineStyle()

                Button {
                    isShowingCountries = true

                } label: {
                    HStack {
                        Text(viewModel.originCountry.name)
                            .bodyStyle()
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .padding()
                }
                .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        })
        .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
        .safariSheet(isPresented: $isShowingHSTarrifInfoWebView, url: viewModel.hsTariffURL)
        .sheet(isPresented: $isShowingCountries, content: {
            NavigationStack {
                SingleSelectionList(title: "Origin Country",
                                    items: viewModel.allCountries,
                                    contentKeyPath: \.name,
                                    selected: $viewModel.originCountry)
            }
            .wooNavigationBarStyle()
        })
    }
}
