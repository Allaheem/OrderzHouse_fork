import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/  
export default defineConfig({
  plugins: [react()],  

  server: {
    // Expose dev server on LAN (e.g. open admin from phone: http://YOUR_IP:5173)
    host: true,
    port: 5173,
    proxy: {
      '/api': {
        target: 'https://orderzhouse-backend.onrender.com', 
        changeOrigin: true,              
        rewrite: (path) => path.replace(/^\/api/, ''), 
      },
      '/upload': {
        target: 'https://orderzhouse-backend.onrender.com', 
        changeOrigin: true,
        rewrite: (path) => path, 
      },
    },
  },
});