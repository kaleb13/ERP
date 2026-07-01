<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import DashboardLayout from './layouts/DashboardLayout.vue'

const route = useRoute()
</script>

<template>
  <RouterView v-if="route.meta.noSidebar" />
  <DashboardLayout v-else>
    <RouterView />
  </DashboardLayout>
</template>

<style>
/* Global reset and setup */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  background-color: #fafafa;
  color: #111827;
}
</style>
