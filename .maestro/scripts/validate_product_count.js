// Validates that the products list has loaded with at least one product.
// Uses the output.visibleProducts count set by the flow.
var count = parseInt(output.visibleProducts, 10);
if (isNaN(count) || count < 1) {
    throw new Error('Expected at least 1 product, found: ' + output.visibleProducts);
}
