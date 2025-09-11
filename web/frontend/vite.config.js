import { defineConfig } from 'vite';
import { resolve } from 'path';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  root: './',
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: resolve(fileURLToPath(new URL('.', import.meta.url)), 'index.html'),
        contact: resolve(fileURLToPath(new URL('.', import.meta.url)), 'contact.html'),
        contactJs: resolve(fileURLToPath(new URL('.', import.meta.url)), 'contact.js')
      }
    }
  }
});
