export default [
  {
    files: ['**/*.js'],
    ignores: [
      'coverage/**',
      'dist/**',
      'node_modules/**',
      '**/*.min.js',
      '**/*.bundle.js',
      '**/*.html',
      'public/**/*.html',
      'public/**',
    ],
    rules: {
      semi: ['error', 'always'],
      quotes: ['error', 'single'],
    },
  },
];
