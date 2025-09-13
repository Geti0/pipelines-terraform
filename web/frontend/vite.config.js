import { defineConfig } from 'vite';
import { resolve } from 'path';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  root: './public',
  build: {
    outDir: '../dist',
    rollupOptions: {
      input: {
        main: resolve(fileURLToPath(new URL('.', import.meta.url)), 'public/index.html'),
        contact: resolve(fileURLToPath(new URL('.', import.meta.url)), 'public/contact.html'),
        debug: resolve(fileURLToPath(new URL('.', import.meta.url)), 'public/debug-contact.html')
      }
    }
  },
  server: {
    open: '/index.html'
  }
});
