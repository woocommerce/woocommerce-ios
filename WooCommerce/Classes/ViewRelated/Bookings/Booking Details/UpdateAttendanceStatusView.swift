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
        case .unattended:
            return UpdateAttendanceStatusView.Localization.unattendedTitle
        case .attended:
            return UpdateAttendanceStatusView.Localization.attendedTitle
        case .unknown:
            return ""
        }
    }

    var information: String {
        switch self {
        case .unattended:
            return UpdateAttendanceStatusView.Localization.unattendedDescription
        case .attended:
            return UpdateAttendanceStatusView.Localization.attendedDescription
        case .unknown:
            return ""
        }
    }

    var iconName: String {
        switch self {
        case .unattended:
            return "calendar.badge.checkmark"
        case .attended:
            return "calendar.and.person"
        case .unknown:
            return ""
        }
    }
}

private extension UpdateAttendanceStatusView {
    enum Constants {
        static let statuses: [BookingAttendanceStatus] = [.unattended, .attended]
        static let statusSelectionDelay: TimeInterval = 0.2
    }

    enum Localization {
        static let title = NSLocalizedString(
            "UpdateAttendanceStatusView.title",
            value: "Update attendance status",
            comment: "Title of the update attendance status bottom sheet."
        )

        static let unattendedTitle = NSLocalizedString(
            "UpdateAttendanceStatusView.unattended.title",
            value: "Unattended",
            comment: "Title for the 'Unattended' attendance status."
        )
        static let unattendedDescription = NSLocalizedString(
            "UpdateAttendanceStatusView.unattended.description",
            value: "The appointment is scheduled but hasn't been attended yet.",
            comment: "Description for the 'Unattended' attendance status."
        )

        static let attendedTitle = NSLocalizedString(
            "UpdateAttendanceStatusView.attended.title",
            value: "Attended",
            comment: "Title for the 'Attended' attendance status."
        )
        static let attendedDescription = NSLocalizedString(
            "UpdateAttendanceStatusView.attended.description",
            value: "The customer arrived and the session took place as planned.",
            comment: "Description for the 'Attended' attendance status."
        )
    }
}

#if DEBUG
struct UpdateAttendanceStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateAttendanceStatusView(selectedStatus: .unattended) { selectedStatus in
            print("Selected status: \(selectedStatus)")
        }
    }
}
#endif
