// Validates that the captured order number is a valid numeric string.
// Used by orders_list_and_search.yaml to verify order data is real.
var orderNum = output.orderNumber;
if (!orderNum || orderNum.trim() === '') {
    throw new Error('Order number is empty');
}
// Order numbers should start with # followed by digits
if (!/^#?\d+$/.test(orderNum.trim())) {
    throw new Error('Order number "' + orderNum + '" does not match expected format #NNN');
}
