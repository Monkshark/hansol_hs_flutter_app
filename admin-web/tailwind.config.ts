import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#3F72AF',
        'primary-dark': '#2B5A8F',
        secondary: '#2E9E6A',
        tertiary: '#7EB8DA',
        dark: { bg: '#17191E', card: '#1E2028', input: '#252830' },
      },
    },
  },
  plugins: [],
};
export default config;
