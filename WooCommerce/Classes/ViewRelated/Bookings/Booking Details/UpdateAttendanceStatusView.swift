import SwiftUI
import Networking

struct UpdateAttendanceStatusView: View {
    @Environment(\.dismiss) private var dismiss
    private let onStatusSelected: (BookingAttendanceStatus) -> Void
    @State private var selectedStatus: BookingAttendanceStatus

    init(selectedStatus: BookingAttendanceStatus, onStatusSelected: @escaping (BookingAttendanceStatus) -> Void) {
        self.onStatusSelected = onStatusSelected
        self._selectedStatus = .init(initialValue: selectedStatus)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(Localization.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ForEach(Constants.statuses, id: \.self) { status in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: status.iconName)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Color(.systemGray))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(status.title)
                                .font(.body.weight(.medium))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(status.information)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if status == selectedStatus {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .tappable {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + Constants.statusSelectionDelay
                        ) {
                            onStatusSelected(status)
                            dismiss()
                        }
                    }
                }
            }
            .padding(.top)
        }
    }
}

private extension BookingAttendanceStatus {
    var title: String {
        switch self {
        case .booked:
            return UpdateAttendanceStatusView.Localization.bookedTitle
        case .checkedIn:
            return UpdateAttendanceStatusView.Localization.checkedInTitle
        case .noShow:
            return UpdateAttendanceStatusView.Localization.noShowTitle
        case .cancelled, .unknown:
            return ""
        }
    }

    var information: String {
        switch self {
        case .booked:
            return UpdateAttendanceStatusView.Localization.bookedDescription
        case .checkedIn:
            return UpdateAttendanceStatusView.Localization.checkedInDescription
        case .noShow:
            return UpdateAttendanceStatusView.Localization.noShowDescription
        case .cancelled, .unknown:
            return ""
        }
    }

    var iconName: String {
        switch self {
        case .booked:
            return "calendar.badge.checkmark"
        case .checkedIn:
            return "calendar.and.person"
        case .noShow:
            return "calendar.badge.exclamationmark"
        case .cancelled, .unknown:
            return ""
        }
    }
}

private extension UpdateAttendanceStatusView {
    enum Constants {
        static let statuses: [BookingAttendanceStatus] = [.booked, .checkedIn, .noShow]
        static let statusSelectionDelay: TimeInterval = 0.2
    }

    enum Localization {
        static let title = NSLocalizedString(
            "UpdateAttendanceStatusView.title",
            value: "Update attendance status",
            comment: "Title of the update attendance status bottom sheet."
        )

        static let bookedTitle = NSLocalizedString(
            "UpdateAttendanceStatusView.booked.title",
            value: "Booked",
            comment: "Title for the 'Booked' attendance status."
        )
        static let bookedDescription = NSLocalizedString(
            "UpdateAttendanceStatusView.booked.description",
            value: "The appointment is scheduled but hasn't happened yet.",
            comment: "Description for the 'Booked' attendance status."
        )

        static let checkedInTitle = NSLocalizedString(
            "UpdateAttendanceStatusView.checkedIn.title",
            value: "Checked-in",
            comment: "Title for the 'Checked-in' attendance status."
        )
        static let checkedInDescription = NSLocalizedString(
            "UpdateAttendanceStatusView.checkedIn.description",
            value: "The customer arrived and the session took place as planned.",
            comment: "Description for the 'Checked-in' attendance status."
        )

        static let noShowTitle = NSLocalizedString(
            "UpdateAttendanceStatusView.noShow.title",
            value: "No-show",
            comment: "Title for the 'No-show' attendance status."
        )
        static let noShowDescription = NSLocalizedString(
            "UpdateAttendanceStatusView.noShow.description",
            value: "The client missed the appointment without canceling in advance.",
            comment: "Description for the 'No-show' attendance status."
        )
    }
}

#if DEBUG
struct UpdateAttendanceStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateAttendanceStatusView(selectedStatus: .booked) { selectedStatus in
            print("Selected status: \(selectedStatus)")
        }
    }
}
#endif
