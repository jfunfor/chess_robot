<template>
  <div id="app">
    <header className="app-header">
      <h1>Шахматная игра</h1>
    </header>
    <main className="app-main">
      <ChessBoard/>
    </main>
  </div>
</template>

<script>
import ChessBoard from './components/ChessBoard.vue';

export default {
  name: 'App',
  components: {
    ChessBoard
  }
};
</script>

<style scoped>
/* Общие стили для приложения */
#app {
  font-family: Arial, sans-serif;
  text-align: center;
  background-color: #f5f5f5;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background-color: #333;
  color: white;
  padding: 20px;
}

.app-main {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
