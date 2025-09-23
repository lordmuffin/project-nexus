// Simple test to verify Jest setup is working
describe('Jest Setup', () => {
  test('should be able to run basic tests', () => {
    expect(1 + 1).toBe(2);
  });

  test('should have testing utilities available', () => {
    expect(jest).toBeDefined();
    expect(expect).toBeDefined();
  });

  test('should have React Native testing setup', () => {
    // This test verifies the setup file loaded correctly
    expect(global.crypto).toBeDefined();
    expect(typeof global.crypto.randomUUID).toBe('function');
  });
});