import SwiftUI

/// A notice that is shown when the bundle configuration is invalid or becomes valid.
struct ConfigurableBundleNoticeView: View {
    /// Contains a message to be shown for the validation error.
    struct ValidationError: Error, Equatable {
        let message: String
    }

    let validationState: Result<Void, ValidationError>

    private var backgroundColor: Color {
        validationState.isSuccess ?
        Color(.withColorStudio(.green, shade: .shade5)):
        Color(.withColorStudio(.blue, shade: .shade10))
    }

    private var title: String {
        validationState.isSuccess ? Localization.validationSuccessTitle: Localization.validationErrorTitle
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                Text(title)
                    .bold()

                if let error = validationState.failure {
                    Text(error.message)
                }
            }
            Spacer()
        }
        .padding(.init(top: Layout.defaultPadding, leading: Layout.defaultPadding, bottom: Layout.defaultPadding, trailing: Layout.defaultPadding))
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(backgroundColor.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(backgroundColor, lineWidth: 1)
        )
    }
}

// MARK: Constants
private extension ConfigurableBundleNoticeView {
    enum Layout {
        static let verticalSpacing: CGFloat = 4
        static let defaultPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let validationErrorTitle = NSLocalizedString(
            "configureBundleProductValidationError.title",
            value: "Configuration required",
            comment: "Title of the error notice when the bundle configuration is currently invalid in the bundle product configuration screen."
        )
        static let validationSuccessTitle = NSLocalizedString(
            "configureBundleProductValidationSuccess.title",
            value: "Configuration complete",
            comment: "Title of the error notice when the bundle configuration is currently valid in the bundle product configuration screen."
        )
    }
}

struct ConfigurableBundleNoticeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Short message.
            ConfigurableBundleNoticeView(validationState: .failure(.init(message: "Choose a variation for Caipi.")))
            // Long message.
            ConfigurableBundleNoticeView(validationState: .failure(.init(
                message: "This bundle requires a total count of 2. Add 1 more of any product to continue."
            )))
            ConfigurableBundleNoticeView(validationState: .success(()))
        }
    }
}
