/** @type {import('tailwindcss').Config} */
// Tokens sampled from the reference screenshots (ui-ss/).
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        canvas: '#000000', // app background
        card: '#111111', // grouped cards, tab bar, sticky footer
        raised: '#1C1C1E', // chips, numpad keys, pills
        well: '#2C2C2E', // disabled button, dividers on cards
        line: '#1E1E1E', // dividers on canvas
        ink: '#FFFFFF', // primary text
        sub: '#8E8E93', // secondary text
        faint: '#58585C', // tertiary text, disabled labels
        danger: '#FF453A',
      },
      fontFamily: {
        sans: [
          '-apple-system', 'BlinkMacSystemFont', '"SF Pro Text"', '"SF Pro Display"',
          '"Helvetica Neue"', 'Inter', 'system-ui', 'sans-serif',
        ],
        mono: ['"SF Mono"', 'ui-monospace', 'Menlo', 'monospace'],
      },
      fontSize: {
        // Measured from the reference by cap height (≈15pt body, 24pt titles).
        caption: ['12px', '16px'],
        footnote: ['13px', '18px'],
        body: ['15px', '20px'],
        headline: ['16px', '21px'],
        title: ['20px', '26px'],
        large: ['25px', '30px'],
        key: ['28px', '34px'],
        display: ['46px', '52px'],
      },
      letterSpacing: {
        label: '0.08em',
      },
      borderRadius: {
        chip: '999px',
        key: '20px',
        btn: '20px',
        card: '20px',
        sheet: '28px',
      },
      spacing: {
        gutter: '20px',
        tabbar: '58px',
        'safe-t': 'env(safe-area-inset-top)',
        'safe-b': 'env(safe-area-inset-bottom)',
      },
    },
  },
  plugins: [],
}
