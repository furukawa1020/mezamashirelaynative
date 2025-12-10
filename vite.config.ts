import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        // Simplified chunking to avoid module resolution issues
        manualChunks: undefined
      }
    }
  }
})
