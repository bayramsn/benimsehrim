/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#D4FFD8',
          100: '#A3FFAD',
          200: '#78E18E',
          300: '#4CC46E',
          400: '#20A74A',
          500: '#006E24',
          600: '#005319',
          700: '#00390F',
          800: '#002106',
          900: '#001304',
        },
        secondary: {
          500: '#8C4E00',
          400: '#FFB74D',
        },
      },
    },
  },
  plugins: [],
}
