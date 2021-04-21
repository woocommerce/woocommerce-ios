/// RefundAction: Defines all of the Actions supported by the ReceiptStore.
///
public enum ReceiptAction: Action {
    case print(order: Order, parameters: ReceiptParameters)
}
