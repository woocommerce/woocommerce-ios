import Foundation

// Mirrors Android's OrderWriteArgumentValidation - same constants, same email regex, same error wording.
enum OrderWriteArgumentValidation {
    static let customerNoteMaxLength = 1000
    static let billingEmailMaxLength = 254

    static func validate(customerNote: String?, billingEmail: String?) -> String? {
        if let note = customerNote, note.count > customerNoteMaxLength {
            return "customer_note must be at most \(customerNoteMaxLength) characters."
        }
        if let email = billingEmail {
            if email.count > billingEmailMaxLength {
                return "billing_email must be at most \(billingEmailMaxLength) characters."
            }
            if email.range(of: emailPattern, options: .regularExpression) == nil {
                return "billing_email must be a valid email address."
            }
        }
        return nil
    }

    private static let emailPattern =
        "^[a-zA-Z0-9+._%-]{1,256}@" +
        "[a-zA-Z0-9][a-zA-Z0-9-]{0,64}" +
        "(\\.[a-zA-Z0-9][a-zA-Z0-9-]{0,25})+$"
}
