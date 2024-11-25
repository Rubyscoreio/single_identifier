module.exports = {
  extends: [
    "plugin:prettier/recommended",
    "plugin:@typescript-eslint/eslint-recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
  ],
  env: {
    browser: false,
    node: true,
    es2022: true,
    mocha: true,
  },
  plugins: ["import", "@typescript-eslint"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: 6,
    sourceType: "module",
    projectFolderIgnoreList: [],
    project: "tsconfig.json",
    ecmaFeatures: {
      modules: true,
      experimentalObjectRestSpread: true,
    },
  },
  overrides: [
    {
      files: ["*.ts"],
      parserOptions: {
        project: ["./tsconfig.json"],
        ecmaVersion: 6,
        sourceType: "module",
      },
    },
  ],
  rules: {
    "linebreak-style": 0,
    indent: "off",
    "@typescript-eslint/restrict-template-expressions": "off",
    "no-use-before-define": "off",
    "@typescript-eslint/no-use-before-define": ["error"],
    "import/extensions": "off",
    "no-shadow": "off",
    "@typescript-eslint/no-shadow": ["error"],
    "template-curly-spacing": "off",
    "arrow-parens": ["error", "always"],
    "no-underscore-dangle": "off",
    "padded-blocks": [
      "error",
      {
        classes: "always",
      },
    ],
    "class-methods-use-this": 0,
    "no-nested-ternary": 0,
    "no-param-reassign": 0,
    "import/prefer-default-export": "off",
    "@typescript-eslint/no-unsafe-call": 0,
    "@typescript-eslint/ban-ts-comment": "off",
    "@typescript-eslint/no-unsafe-member-access": 0,
    "@typescript-eslint/no-unsafe-assignment": 0,
    "@typescript-eslint/no-unsafe-argument": "off",
    "@typescript-eslint/unbound-method": 0,
    "@typescript-eslint/no-explicit-any": "off",
    "prettier/prettier": [
      "error",
      {
        endOfLine: "auto",
      },
    ],
  },
  settings: {
    node: {
      allowModules: ["hardhat"],
      resolvePaths: ["node_modules/@types"],
      tryExtensions: [".ts", ".d.ts"],
    },
    "import/parsers": {
      "@typescript-eslint/parser": [".ts", ".d.ts"],
    },
    "import/resolver": {
      typescript: {
        alwaysTryTypes: true,
      },
    },
  },
};
