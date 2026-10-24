# Inline Slice Build (reference)

Companion to `implement-feature` full mode. Steps 2–5 of a slice, for when Phase 1.6 chose to build slices inline rather than delegate. Steps 1 and 6 stay in `full-mode.md`. Read `tdd.md` alongside this — it holds the testing rules these steps apply.

**Step 2: Plan Before Coding**
 
- Discuss public interfaces (what should the API look like from a caller's perspective?)
- Identify critical behaviours to test
- Map out a test strategy — which slice of behaviour gets the first test?
- **Custom hook/wrapper check:** If the slice's `Gotchas` or `README.md` references method calls on custom hooks or wrappers, read the hook source before writing any tests or code. Custom wrappers frequently shadow or redefine methods from the underlying library — assuming the API matches the library docs leads to hard-to-debug test failures. Look for spread patterns like `{ ...libraryResult, customMethod }` where `customMethod` overrides a library method of the same name.
**Step 3: Tracer Bullet (First Test)**

- **Test runner:** use the commands resolved in Phase 1. Only re-check `package.json` if a command fails or this slice needs a narrower invocation.
- Write ONE test for the first observable behaviour
- Run it — it should fail (RED)
- Write the minimal code to pass (GREEN)
- **Fixture realism check:** Before marking GREEN, verify your test fixture reflects the actual production input format — not a sanitised version that sidesteps the hard case. Ask: does the real input have special encoding, wrapping, escaping, or structural quirks that the code must handle? If so, the fixture must include them. Common traps: using plain strings when real data is encoded (base64, CDATA, URL-encoded), using flat structures when real responses are nested, or omitting optional fields that the code branches on. A test that passes on a simplified fixture but fails on real data is worse than no test: it gives false confidence and delays discovering the bug until production.
**Step 4: Incremental Loop (Remaining Behaviours)**
 
- Write the next test → it fails
- Write minimal code to pass → it passes
- Repeat until all acceptance criteria are met
- No speculative features. No anticipating future tests.
**Step 5: Refactor (Only After All Tests Pass)**
 
- Extract duplication
- Deepen modules (push complexity behind simple interfaces)
- Apply SOLID where it falls out naturally
- Run tests after each refactor step — if they break, you went too far
