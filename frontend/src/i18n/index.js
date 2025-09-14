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
      
      // Vue i18n passes a context object with helper functions
      // ctx.named is a function to get named parameters
      // ctx.list is a function to get positional parameters
      
      // Handle named parameters like {name}, {count}, {first}, {last}
      result = result.replace(/\{(\w+)\}/g, (match, key) => {
        if (ctx && typeof ctx.named === 'function') {
          const value = ctx.named(key)
          return value !== undefined ? String(value) : match
        }
        return match
      })
      
      // Handle positional parameters like {0}, {1}
      result = result.replace(/\{(\d+)\}/g, (match, index) => {
        if (ctx && typeof ctx.list === 'function') {
          const i = parseInt(index, 10)
          const value = ctx.list(i)
          return value !== undefined ? String(value) : match
        }
        return match
      })
      
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