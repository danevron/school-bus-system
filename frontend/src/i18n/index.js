import { createI18n } from 'vue-i18n'
import en from '../locales/en.json'
import he from '../locales/he.json'

const messages = {
  en,
  he
}

const i18n = createI18n({
  locale: localStorage.getItem('language') || 'en', // Default to English
  fallbackLocale: 'en',
  messages,
  legacy: false, // Use Composition API mode
  globalInjection: true,
  // Disable message compiler to fix CSP issues in production
  messageCompiler: undefined,
  // Disable warnings about missing keys in production
  missingWarn: process.env.NODE_ENV !== 'production',
  fallbackWarn: process.env.NODE_ENV !== 'production'
})

export default i18n