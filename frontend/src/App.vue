<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import DashboardLayout from './layouts/DashboardLayout.vue'

const route = useRoute()
</script>

<template>
  <div v-if="route.meta.noSidebar" class="fullscreen-page">
    <RouterView />
  </div>
  <DashboardLayout v-else>
    <RouterView />
  </DashboardLayout>
</template>

<style>
/* Global reset and setup */
*,
*::before,
*::after {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html,
body {
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
  overflow: hidden;
}

#app {
  height: 100%;
  width: 100%;
  overflow: hidden;
}

.fullscreen-page {
  height: 100%;
  width: 100%;
  overflow-y: auto;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  background-color: #fafafa;
  color: #111827;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
