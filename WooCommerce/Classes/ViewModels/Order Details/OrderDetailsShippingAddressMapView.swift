import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct OrderDetailsShippingAddressMapView: View {
    let viewModel: OrderDetailsShippingAddressMapViewModel

    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.mapState {
            case let .loaded(coordinate, cameraPosition):
                Map(position: .constant(cameraPosition)) {
                    Annotation("", coordinate: coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                            .background(Color.white.clipShape(Circle()))
                    }
                }
                .mapStyle(.standard)
                .mapControlVisibility(.hidden)
                .disabled(true) // Disable user interaction (scrolling, zooming)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.onMapTapped?()
                }
            case .loading:
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            case .failed, .none:
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "map")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.onMapTapped?()
                    }
            }
        }
        .frame(height: viewModel.mapHeight)
        .renderedIf(viewModel.isValidAddress)
    }
}

@available(iOS 17.0, *)
private extension OrderDetailsShippingAddressMapView {
    enum Layout {
        static let cornerRadius: CGFloat = 8
    }
}

#if DEBUG

import struct Yosemite.Address

@available(iOS 17.0, *)
#Preview {
    let sampleAddress = Address(
        firstName: "",
        lastName: "",
        company: "",
        address1: "60 29th Street #343",
        address2: "Suite 100",
        city: "San Francisco",
        state: "CA",
        postcode: "94102",
        country: "US",
        phone: "+1-555-0123",
        email: "woo@example.com"
    )
    let viewModel = OrderDetailsShippingAddressMapViewModel(shippingAddress: sampleAddress)
    return OrderDetailsShippingAddressMapView(viewModel: viewModel)
        .padding()
}

@available(iOS 17.0, *)
#Preview("Invalid address") {
    let sampleAddress = Address(
        firstName: "",
        lastName: "",
        company: "",
        address1: "",
        address2: "",
        city: "ZZ",
        state: "",
        postcode: "",
        country: "US",
        phone: "+1-555-0123",
        email: "woo@example.com"
    )
    let viewModel = OrderDetailsShippingAddressMapViewModel(shippingAddress: sampleAddress)
    return OrderDetailsShippingAddressMapView(viewModel: viewModel)
        .padding()
}

@available(iOS 17.0, *)
#Preview("No address") {
    let viewModel = OrderDetailsShippingAddressMapViewModel(shippingAddress: nil)
    return OrderDetailsShippingAddressMapView(viewModel: viewModel)
        .padding()
}

#endif
