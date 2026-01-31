/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                dark: {
                    bg: '#000000',
                    card: '#0f0f0f',
                    border: '#1f1f1f',
                    hover: '#1a1a1a',
                },
                accent: {
                    purple: '#8b5cf6',
                    blue: '#3b82f6',
                    green: '#10b981',
                    red: '#ef4444',
                    yellow: '#f59e0b',
                    pink: '#ec4899',
                },
            },
            backgroundImage: {
                'gradient-purple': 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                'gradient-blue': 'linear-gradient(135deg, #3b82f6 0%, #1e40af 100%)',
                'gradient-green': 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                'gradient-red': 'linear-gradient(135deg, #ef4444 0%, #b91c1c 100%)',
                'gradient-yellow': 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                'gradient-pink': 'linear-gradient(135deg, #ec4899 0%, #be185d 100%)',
            },
            animation: {
                'fade-in': 'fadeIn 0.3s ease-in',
                'slide-in': 'slideIn 0.3s ease-out',
                'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
            },
            keyframes: {
                fadeIn: {
                    '0%': { opacity: '0' },
                    '100%': { opacity: '1' },
                },
                slideIn: {
                    '0%': { transform: 'translateY(10px)', opacity: '0' },
                    '100%': { transform: 'translateY(0)', opacity: '1' },
                },
            },
        },
    },
    plugins: [],
}
