# Design Practices (reference)

Companion to `implement-feature`. Not loaded by default — read a section when the
situation below applies, not as a matter of course.

- **Worked test examples** — when a test's shape is genuinely unclear.
- **Interface design / deep modules** — when a slice introduces a new module.
- **Designing for mockability** — when a slice introduces a new system boundary.

### Example: Good vs Bad
 
```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
 
// GOOD: Tests observable behaviour
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```
 
### Another Example: Interface vs Bypass
 
```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});
 
// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```
 
## Interface Design for Testability
 
Good interfaces make testing natural.
 
### 1. Accept Dependencies, Don't Create Them
 
```typescript
// Testable
function processOrder(order, paymentGateway) {}
 
// Hard to test
function processOrder(order) {
  const gateway = new StripeGateway();
}
```
 
### 2. Return Results, Don't Produce Side Effects
 
```typescript
// Testable
function calculateDiscount(cart): Discount {}
 
// Hard to test
function applyDiscount(cart): void {
  cart.total -= discount;
}
```
 
### 3. Small Surface Area
 
Fewer methods = fewer tests needed. Fewer params = simpler test setup. If you need many params, that's a hint the abstraction is wrong.
 
## Deep Modules
 
From *A Philosophy of Software Design*:
 
**Deep module** = small interface + lots of implementation (the goal).
 
```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│ Deep Implementation │  ← Complex logic hidden
│                     │
└─────────────────────┘
```
 
**Shallow module** = large interface + little implementation (avoid).
 
```
┌─────────────────────────────────┐
│        Large Interface          │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```
 
When designing interfaces, ask: can I reduce the number of methods? Can I simplify the parameters? Can I hide more complexity inside?
 
### Designing for Mockability
 
At system boundaries, design interfaces that are easy to mock.
 
**1. Use dependency injection**
 
```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}
 
// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```
 
**2. Prefer SDK-style interfaces over generic fetchers**
 
```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};
 
// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```
 
The SDK approach means each mock returns one specific shape, no conditional logic in test setup, easier to see which endpoints a test exercises, and type safety per endpoint.
 
