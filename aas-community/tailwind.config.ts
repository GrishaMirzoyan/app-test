import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Antarctic palette — ice, deep water, penguin black.
        ice: {
          50: "#f2f8fc",
          100: "#e3eff8",
          200: "#c3def0",
          300: "#92c4e3",
        },
        deep: {
          700: "#13314f",
          800: "#0d2438",
          900: "#081826",
        },
      },
      fontFamily: {
        sans: ["ui-sans-serif", "system-ui", "Segoe UI", "Roboto", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
