import SwiftUI

struct UpdateAttendanceStatusView: View {
    private let statuses = AttendanceStatus.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(Localization.title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(statuses) { status in
                HStack(spacing: 16) {
                    Image(systemName: status.iconName)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Color(.systemGray))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.title)
                            .font(.body.weight(.medium))
                        Text(status.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding(.top)
    }
}

private extension UpdateAttendanceStatusView {
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

private enum AttendanceStatus: CaseIterable, Identifiable {
    case booked
    case checkedIn
    case noShow

    var id: Self { self }

    var title: String {
        switch self {
        case .booked:
            return UpdateAttendanceStatusView.Localization.bookedTitle
        case .checkedIn:
            return UpdateAttendanceStatusView.Localization.checkedInTitle
        case .noShow:
            return UpdateAttendanceStatusView.Localization.noShowTitle
        }
    }

    var description: String {
        switch self {
        case .booked:
            return UpdateAttendanceStatusView.Localization.bookedDescription
        case .checkedIn:
            return UpdateAttendanceStatusView.Localization.checkedInDescription
        case .noShow:
            return UpdateAttendanceStatusView.Localization.noShowDescription
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
        }
    }
}

#if DEBUG
struct UpdateAttendanceStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateAttendanceStatusView()
    }
}
#endif
