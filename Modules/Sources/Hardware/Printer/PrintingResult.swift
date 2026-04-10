/// Encapsulates possible results of a printing request
///
public enum PrintingResult {
    /// Successful print job
    case success
    /// User canceled the print job
    case cancel
    /// Printing failed
    case failure(Error)
}
