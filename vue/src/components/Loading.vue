<script>
export default {
  props: {
    color: {
      default: 'white',
      type: String
    },
    size: {
      default: 28,
      type: Number
    },
    borderThickness: {
      default: 4,
      type: Number
    },
  },
  computed: {
    cssProps() {
      return {
        '--size': `${this.size}px`,
        '--border-thickness': `${this.borderThickness}px`,
      }
    }
  }
}
</script>
<template>
  <span aria-hidden="true" class="spinner-border text-dark" :class="{inverted: color === 'black'}" :style="cssProps"></span>
</template>
<style scoped>
.inverted {
  filter: invert(100%);
}
.spinner-border {
  display: inline-block;
  vertical-align: text-bottom;
  border: var(--border-thickness) solid;
  border-right: var(--border-thickness) solid transparent;
  border-radius: 50%;
  -webkit-animation: spinner-border .75s linear infinite;
  animation: spinner-border .75s linear infinite;
  box-sizing: border-box;
  text-align: center!important;
  width: var(--size);
  height: var(--size);
}
@keyframes spinner-border {
  to {
    -webkit-transform: rotate(360deg);
    transform: rotate(360deg);
  }
}
</style>