export default [
  {
    files: ['**/*.js'],
    ignores: ['coverage/**', 'dist/**', 'node_modules/**', '**/*.min.js', '**/*.bundle.js'],
    rules: {
      semi: ['error', 'always'],
      quotes: ['error', 'single'],
    },
  },
];
