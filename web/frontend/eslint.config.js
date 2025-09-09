export default [
  {
    files: ['**/*.js'],
    ignores: ['coverage/**', 'dist/**', 'node_modules/**'],
    rules: {
      semi: ['error', 'always'],
      quotes: ['error', 'single'],
    },
  },
];
