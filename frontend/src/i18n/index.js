import { createI18n } from 'vue-i18n'
import en from '../locales/en.json'
import he from '../locales/he.json'

const messages = {
  en,
  he
}

// CSP-safe message compiler that handles parameter interpolation
const createMessageCompiler = () => {
  return (message, options) => {
    // If it's not a string, return as-is
    if (typeof message !== 'string') {
      return () => message
    }

    // Check if message has parameters like {name}, {count}, etc.
    const hasParams = /\{[^}]+\}/.test(message)
    
    if (!hasParams) {
      // Simple string without parameters
      return () => message
    }

    // Return a function that handles parameter substitution
    return (ctx) => {
      let result = message
      
      // Handle named parameters like {name}, {count}, {first}, {last}
      if (ctx && ctx.named) {
        result = result.replace(/\{(\w+)\}/g, (match, key) => {
          return ctx.named[key] !== undefined ? String(ctx.named[key]) : match
        })
      }
      
      // Handle positional parameters like {0}, {1}
      if (ctx && ctx.list) {
        result = result.replace(/\{(\d+)\}/g, (match, index) => {
          const i = parseInt(index, 10)
          return ctx.list[i] !== undefined ? String(ctx.list[i]) : match
        })
      }
      
      return result
    }
  }
}

const i18n = createI18n({
  locale: localStorage.getItem('language') || 'en', // Default to English
  fallbackLocale: 'en',
  messages,
  legacy: false, // Use Composition API mode
  globalInjection: true,
  // Use our CSP-safe compiler
  messageCompiler: createMessageCompiler(),
  // Disable warnings in production
  missingWarn: process.env.NODE_ENV !== 'production',
  fallbackWarn: process.env.NODE_ENV !== 'production'
})

export default i18n