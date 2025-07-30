import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct OrderDetailsShippingAddressMapView: View {
    let viewModel: OrderDetailsShippingAddressMapViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isValidAddress {
                Group {
                    if let coordinate = viewModel.coordinate {
                        Map(position: .constant(viewModel.cameraPosition)) {
                            Annotation(viewModel.shippingAddress?.fullNameWithCompany ?? "Address", coordinate: coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                                    .background(Color.white.clipShape(Circle()))
                            }
                        }
                        .mapStyle(.standard)
                        .mapControlVisibility(.hidden)
                        .disabled(true) // Disable user interaction (scrolling, zooming)
                        .frame(height: viewModel.mapHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.onMapTapped?()
                        }
                    } else if viewModel.isGeocoding {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: viewModel.mapHeight)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    } else {
                        // Empty state or failed geocoding
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: viewModel.mapHeight)
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
            }
        }
    }
}
