import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'

// Global language state
const selectedLanguage = ref(localStorage.getItem('language') || 'en')

export function useLanguage() {
  const { locale } = useI18n()
  
  const languageOptions = ref([
    { label: 'English', value: 'en' },
    { label: 'עברית', value: 'he' }
  ])
  
  const isRTL = computed(() => selectedLanguage.value === 'he')
  
  const changeLanguage = (newLanguage = selectedLanguage.value) => {
    selectedLanguage.value = newLanguage
    locale.value = newLanguage
    localStorage.setItem('language', newLanguage)
    
    // Apply RTL for Hebrew
    if (newLanguage === 'he') {
      document.documentElement.dir = 'rtl'
      document.documentElement.lang = 'he'
    } else {
      document.documentElement.dir = 'ltr'
      document.documentElement.lang = 'en'
    }
  }
  
  const initializeLanguage = () => {
    const savedLanguage = localStorage.getItem('language') || 'en'
    selectedLanguage.value = savedLanguage
    changeLanguage(savedLanguage)
  }
  
  return {
    selectedLanguage,
    languageOptions,
    isRTL,
    changeLanguage,
    initializeLanguage
  }
}