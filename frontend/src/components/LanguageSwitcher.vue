<template>
  <div class="language-switcher">
    <Button
      @click="toggle"
      :aria-label="$t('common.language')"
      severity="secondary"
      variant="text"
      class="language-button"
      size="small"
    >
      <span class="flag-container">
        <span :class="currentFlagClass"></span>
        <i class="pi pi-chevron-down toggle-icon" :class="{ 'rotated': showMenu }"></i>
      </span>
    </Button>
    
    <div v-if="showMenu" class="language-menu" @click.stop>
      <div 
        v-for="option in languageOptions" 
        :key="option.value"
        @click="selectLanguage(option.value)"
        class="language-option"
        :class="{ active: selectedLanguage === option.value }"
      >
        <span :class="getFlagClass(option.value)"></span>
        <span class="language-label">{{ option.label }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useLanguage } from '../composables/useLanguage.js'

export default {
  name: 'LanguageSwitcher',
  setup() {
    const { selectedLanguage, languageOptions, changeLanguage } = useLanguage()
    const showMenu = ref(false)
    
    const currentFlagClass = computed(() => {
      return getFlagClass(selectedLanguage.value)
    })
    
    const getFlagClass = (lang) => {
      const flagClasses = {
        'en': 'flag flag-us',
        'he': 'flag flag-il'
      }
      return flagClasses[lang] || 'flag flag-us'
    }
    
    const toggle = () => {
      showMenu.value = !showMenu.value
    }
    
    const selectLanguage = (lang) => {
      changeLanguage(lang)
      showMenu.value = false
    }
    
    const closeMenu = (event) => {
      if (!event.target.closest('.language-switcher')) {
        showMenu.value = false
      }
    }
    
    onMounted(() => {
      document.addEventListener('click', closeMenu)
    })
    
    onUnmounted(() => {
      document.removeEventListener('click', closeMenu)
    })
    
    return {
      selectedLanguage,
      languageOptions,
      showMenu,
      currentFlagClass,
      toggle,
      selectLanguage,
      getFlagClass
    }
  }
}
</script>

<style scoped>
.language-switcher {
  position: relative;
  z-index: 1001;
}

.language-button {
  color: white !important;
  padding: 0.5rem !important;
  border: none !important;
  background: transparent !important;
  transition: background-color 0.2s ease;
}

.language-button:hover {
  background-color: rgba(255, 255, 255, 0.1) !important;
}

.flag-container {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.flag {
  width: 20px;
  height: 15px;
  border-radius: 3px;
  display: inline-block;
  background-size: cover;
  background-position: center;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}

.flag-us {
  background-image: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 30"><defs><clipPath id="us"><path d="M0 0v30h60V0z"/></clipPath></defs><path fill="%23b22234" d="M0 0v30h60V0z"/><path stroke="%23fff" stroke-width="2" d="M0 2h60M0 6h60M0 10h60M0 14h60M0 18h60M0 22h60M0 26h60"/><path fill="%233c3b6e" d="M0 0v16h24V0z"/></svg>');
}

.flag-il {
  background-image: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 660 480"><defs><g id="il-star"><path fill="%230038b8" d="m0-29 8.7 26.8L27-13.4l-21.7 16L27-13.4"/><path fill="%230038b8" d="m0-29-8.7 26.8L-27-13.4l21.7 16-21.7 16"/></g></defs><path fill="%23fff" d="M0 0h660v480H0z"/><path fill="%230038b8" d="M0 0h660v60H0zm0 420h660v60H0z"/><g stroke="%230038b8" stroke-width="5.4" transform="translate(330 240)"><circle r="45" fill="none"/><use href="%23il-star" transform="rotate(0)"/><use href="%23il-star" transform="rotate(60)"/><use href="%23il-star" transform="rotate(120)"/><use href="%23il-star" transform="rotate(180)"/><use href="%23il-star" transform="rotate(240)"/><use href="%23il-star" transform="rotate(300)"/></g></svg>');
}

.toggle-icon {
  font-size: 0.7rem;
  color: rgba(255, 255, 255, 0.8);
  transition: transform 0.2s ease;
}

.toggle-icon.rotated {
  transform: rotate(180deg);
}

.language-menu {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  background: white;
  border: 1px solid var(--p-surface-border);
  border-radius: var(--p-border-radius);
  box-shadow: var(--p-shadow-lg);
  min-width: 140px;
  overflow: hidden;
  z-index: 1002;
  animation: fadeInDown 0.2s ease-out;
  transform-origin: top right;
}

.language-option {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  cursor: pointer;
  transition: background-color 0.2s ease;
  color: var(--p-text-color);
  font-size: 0.9rem;
}

.language-option:hover {
  background-color: var(--p-surface-hover);
}

.language-option.active {
  background-color: var(--p-primary-50);
  color: var(--p-primary-700);
  font-weight: 500;
}

.language-label {
  white-space: nowrap;
}

/* RTL Support */
[dir="rtl"] .language-menu {
  right: auto;
  left: 0;
}

[dir="rtl"] .flag-container {
  flex-direction: row-reverse;
}

[dir="rtl"] .language-option {
  flex-direction: row-reverse;
  text-align: right;
}

/* Mobile optimizations */
@media (max-width: 640px) {
  .language-menu {
    min-width: 120px;
  }
  
  .language-option {
    padding: 0.6rem 0.8rem;
    font-size: 0.85rem;
  }
  
  .flag {
    width: 18px;
    height: 13px;
  }
}

/* Animations */
@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-10px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}
</style>