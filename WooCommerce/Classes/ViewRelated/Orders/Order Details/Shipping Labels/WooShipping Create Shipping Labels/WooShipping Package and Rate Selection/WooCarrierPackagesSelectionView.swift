import SwiftUI

struct WooPackageCarrier {
    let id: UUID
    let name: String
    let icon: String
    let packageGroups: [WooPackageGroup]
}

struct WooPackageGroup {
    let id: UUID = UUID()
    let name: String
    let packages: [any WooPackageDataRepresentable]
}

struct WooCarrierPackageData: WooPackageDataRepresentable {
    let id: UUID = UUID()
    let name: String
    let dimensions: String
    let weight: String
}

struct WooCarrierPackagesSelectionView: View {
    let carriersPackages: [WooPackageCarrier]
    @State private var selectedPackageId: UUID? = nil  // Track the selected package index
    @State private var starredPackages: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            if let firstCarrier = carriersPackages.first {
                Divider()
                List {
                    ForEach(firstCarrier.packageGroups, id: \.id) { packageGroup in
                        Section {
                            ForEach(packageGroup.packages, id: \.id) { package in
                                PackageOptionView(
                                    isSelected: selectedPackageId == package.id, // Check if this package is selected
                                    package: package,
                                    packageType: nil,
                                    showTopDivider: false,
                                    tapAction: {
                                        selectedPackageId = selectedPackageId == package.id ? nil : package.id
                                    },
                                    starAction: {
                                        if starredPackages.contains(package.id) {
                                            starredPackages.remove(package.id)
                                        }
                                        else {
                                            starredPackages.insert(package.id)
                                        }
                                    },
                                    starred: starredPackages.contains(package.id)
                                )
                                .alignmentGuide(.listRowSeparatorLeading) { _ in
                                    return 16
                                }
                            }
                        } header: {
                            HStack {
                                Text(packageGroup.name.uppercased())
                                    .foregroundColor(.secondary)
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .background(Color.clear)
                        }
                        .listRowInsets(.zero)
                    }
                }
                .listStyle(.plain)
                Divider()
                Button(WooShippingAddPackageView.Localization.addPackage) {
                }
                .disabled(selectedPackageId == nil)
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
    }
}
