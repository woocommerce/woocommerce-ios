import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    final class NotesContent: ObservableObject {
        @Published var value: String = ""

        func update(with booking: Booking) {
            value = booking.note
        }
    }
}
