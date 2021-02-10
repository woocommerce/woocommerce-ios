/// The possible events from a connected reader.
public enum CardReaderEvent {
    // A card was inserted.
    case cardInserted

    // A card was removed.
    case cardRemoved

    // Low battery warning.
    case lowBattery

    // The card reader disconnected.
    case disconnected
}
