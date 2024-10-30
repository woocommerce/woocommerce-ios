import SwiftUI

protocol WooPackageDataRepresentable {
    var id: UUID { get }
    var name: String { get }
    var dimensions: String { get }
    var weight: String { get }
    var type: String { get }
    var packageType: String { get }
}

struct WooSavedPackageData: WooPackageDataRepresentable {
    let id: UUID = UUID()
    let name: String
    let type: String
    let packageType: String
    let dimensions: String
    let weight: String
}

struct WooSavedPackagesSelectionView: View {
    @State private var selectedPackageId: UUID? = nil  // Track the selected package index
    let packages: [any WooPackageDataRepresentable]
    let addPackageAction: (WooPackageDataRepresentable) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            List {
                ForEach(packages, id: \.id) { package in
                    PackageOptionView(
                        isSelected: selectedPackageId == package.id, // Check if this package is selected
                        package: package,
                        showTopDivider: false,
                        showType: true,
                        tapAction: {
                            selectedPackageId = selectedPackageId == package.id ? nil : package.id
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
                addPackageButtonTapped()
            }
            .disabled(selectedPackageId == nil || packages.isEmpty)
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }

    private func addPackageButtonTapped() {
        // call addPackageAction with data
        if let selectedPackageId {
            for packageItem in packages {
                if selectedPackageId == packageItem.id {
                    addPackageAction(packageItem)
                    return
                }
            }
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
    var package: WooPackageDataRepresentable
    var showTopDivider: Bool
    var showType: Bool
    var tapAction: () -> Void
    var starAction: (() -> Void)?
    var starred: Bool?

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(.withColorStudio(.wooCommercePurple, shade: .shade60)) : .gray)
                    .font(.title)
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    if showType, package.type.isNotEmpty {
                        Text(package.type)
                            .captionStyle()
                    }
                    Text(package.name)
                        .bodyStyle()
                    HStack {
                        Text(package.dimensions)
                        Text("•")
                        Text(package.weight)
                    }
                    .subheadlineStyle()
                }
                .padding(.leading, Constants.textContentLeadingPadding)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                tapAction()
            }
            .padding(Constants.contentPadding)
            if let starAction, let starred {
                VStack {
                    Image(systemName: starred ? "star.fill": "star")
                        .foregroundStyle(.secondary)
                        .padding(Constants.contentPadding)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    starAction()
                }
            }
        }
    }
}
