import SwiftUI

/// Wrapper for technical details to make them presentable in a sheet
///
struct TechnicalDetailsItem: Identifiable {
    let id = UUID()
    let details: String
}

/// View for displaying technical error details with copy functionality
///
struct TechnicalDetailsView: View {
    let technicalDetails: String
    @Environment(\.dismiss) var dismiss
    @State private var notice: Notice?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(technicalDetails)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(Localization.copy) {
                        UIPasteboard.general.string = technicalDetails
                        notice = Notice(message: Localization.copiedAlertMessage, feedbackType: .success)
                    }
                }
            }
            .notice($notice)
        }
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "technicalDetailsView.title",
            value: "Technical details",
            comment: "Title of technical details screen"
        )
        static let close = NSLocalizedString(
            "technicalDetailsView.close",
            value: "Close",
            comment: "Button to close technical details screen"
        )
        static let copy = NSLocalizedString(
            "technicalDetailsView.copy",
            value: "Copy",
            comment: "Button to copy technical details to clipboard"
        )
        static let copiedAlertMessage = NSLocalizedString(
            "technicalDetailsView.copiedAlert.message",
            value: "Technical details have been copied to your clipboard.",
            comment: "Alert message shown when technical details are copied"
        )
        static let ok = NSLocalizedString(
            "technicalDetailsView.ok",
            value: "OK",
            comment: "OK button for copied confirmation alert"
        )
    }
}

#Preview("Tool") {
    NavigationView {
        TechnicalDetailsView(
            technicalDetails:
            """
            Error Type: Decoding Error
            Issue: Type Mismatch
            Expected Type: Int
            Coding Path: test  → id
            """)
    }
}
