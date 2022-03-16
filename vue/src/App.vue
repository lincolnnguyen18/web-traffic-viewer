<script>
import All from './components/All.vue'
import Countries from './components/Countries.vue'
export default {
  data() {
    return {
      currentPage: 'all',
      pages: ['all', 'countries']
    }
  },
  computed: {
  },
  methods: {
    page_icon(page) {
      switch (page) {
        case 'all':
          return 'bar_chart'
        case 'countries':
          return 'public'
      }
    },
  },
  components: { All, Countries }
}
</script>

<template>
<div class="buttons">
  <span
    v-for="page in pages"
    :key="page"
    @click="currentPage = page"
    :class="['material-icons-round', { active: currentPage === page }]"
  >{{ page_icon(page) }}</span>
</div>
<component :is="currentPage"></component>
</template>

<style>
html, body, #app {
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
}
#app {
  display: flex;
}
.buttons {
  position: absolute;
  bottom: 0;
  left: 0;
  color: #bbb;
  display: flex;
  gap: 16px;
  margin-left: 16px;
  margin-bottom: 16px;
}
.buttons span {
  font-size: 32px;
  user-select: none;
  cursor: pointer;
}
.active {
  color: #000;
}
</style>
