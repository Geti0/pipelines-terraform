const globals = require("globals");
const js = require("@eslint/js");

module.exports = [
  js.configs.recommended,
  {
    languageOptions: {
      globals: {
        ...globals.node,
        ...globals.jest
      },
      ecmaVersion: 2022,
      sourceType: "commonjs"
    },
    rules: {
      "no-unused-vars": "error",
      "no-console": "off",
      "semi": ["error", "always"],
      "quotes": ["error", "single"],
      "indent": ["error", 4],
      "no-trailing-spaces": "error",
      "eol-last": "error"
    }
  }
];
