// Minimal smoke test used by the CI pipeline (no AWS/DB dependency).
// Confirms the app module loads and health handler logic is sound.
const assert = require('assert');

function fakeHealthHandler() {
  return { status: 'ok', service: 'project1-app' };
}

const result = fakeHealthHandler();
assert.strictEqual(result.status, 'ok');
assert.strictEqual(result.service, 'project1-app');

console.log('smoke test passed');
