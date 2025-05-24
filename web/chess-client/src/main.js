import { createApp } from 'vue'
import App from './App.vue'
import 'chessboardjs/www/css/chessboard.css'

// Устанавливаем jQuery глобально для chessboard.js
import $ from 'jquery';
window.$ = $;
window.jQuery = $;


createApp(App).mount('#app')
