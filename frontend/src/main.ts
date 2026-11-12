import { createApp } from 'vue';
import './style.css';
import App from './App.vue';
import router from './router';
import AppButton from './components/AppButton.vue';
import BaseButton from './components/BaseButton.vue';

const app = createApp(App);
app.component('AppButton', AppButton);
app.component('BaseButton', BaseButton);
app.use(router).mount('#app');
