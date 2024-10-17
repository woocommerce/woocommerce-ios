import SwiftUI

protocol WooSavedPackageDataRepresentable {
    var name: String { get }
    var type: String { get }
    var dimensions: String { get }
    var weight: String { get }
}

struct WooSavedPackageData: WooSavedPackageDataRepresentable {
    let name: String
    let type: String
    let dimensions: String
    let weight: String
}

struct WooSavedPackagesSelectionView: View {
    @State private var selectedPackageIndex: Int? = nil  // Track the selected package index
    let packages: [WooSavedPackageDataRepresentable]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            List {
                ForEach(packages.indices, id: \.self) { index in
                    PackageOptionView(
                        isSelected: selectedPackageIndex == index, // Check if this package is selected
                        package: packages[index],
                        showTopDivider: false,
                        action: {
                            selectedPackageIndex = selectedPackageIndex == index ? nil : index
                        }
                    )
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        return 16
                    }
                    .swipeActions {
                        Button {
                            // remove package
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(Color.withColorStudio(name: .red, shade: .shade50))
                    }
                }
                .listRowInsets(.zero)
            }
            .listStyle(.plain)
            Divider()
            Button(WooShippingAddPackageView.Localization.addPackage) {
            }
            .disabled(selectedPackageIndex == nil || packages.isEmpty)
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }
}

struct PackageOptionView: View {
    enum Constants {
        static let verticalSpacing: CGFloat = 4.0
        static let textContentLeadingPadding: CGFloat = 4.0
        static let contentPadding: CGFloat = 16.0
    }

    var isSelected: Bool
    var package: WooSavedPackageDataRepresentable
    var showTopDivider: Bool
    var action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color(.withColorStudio(.wooCommercePurple, shade: .shade60)) : .gray)
                .font(.title)
            VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                Text(package.type)
                    .captionStyle()
                Text(package.name)
                    .bodyStyle()
                HStack {
                    Text(package.dimensions)
                    Text("•")
                    Text(package.weight)
                }
                .subheadlineStyle()
                .foregroundColor(.gray)
            }
            .padding(.leading, Constants.textContentLeadingPadding)
            Spacer()
        }
        .padding(Constants.contentPadding)
        .onTapGesture {
            action()
        }
    }
}
