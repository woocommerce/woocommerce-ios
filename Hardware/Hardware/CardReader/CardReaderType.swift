/// Card reader type. Indicates if a reader is meant to be used
/// handheld or as a countertop device
public enum CardReaderType {
    /// Handled reader for use with mobile applications
    case mobile
    /// Counter top reader
    case counterTop
    /// Reader not supported
    case notSupported
}
