<script>
import Loading from './Loading.vue'
export default {
  data() {
    return {
      search: '',
      mode: 'all',
      visitors: [],
      details: [],
      refreshing: false,
      altDown: false,
      searchFocused: false
    }
  },
  methods: {
    clearSearch() {
      this.search = ''
      this.$refs.searchInput.focus()
    },
    setMode(mode) {
      this.mode = mode
    },
    onScroll ({ target: { scrollTop, clientHeight, scrollHeight }}) {
      if (scrollTop + clientHeight >= scrollHeight) {
        console.log('scrolled to bottom')
        this.loadMoreVisits()
      }
    },
    loadMoreVisits: async function () {
      fetch(`https://demo10.lincolnnguyen18.com/getVisits?lastId=${this.visitors[this.visitors.length - 1].id}&search=${this.search}`)
        .then(res => res.json())
        .then(data => {
          data = this.reformatVisits(data)
          this.visitors = this.visitors.concat(data)
        })
    },
    reformatVisits(data) {
      data.forEach(visit => {
        visit.date = new Date(visit.date)
        // don't display seconds
        visit.date = visit.date.toLocaleDateString() + ' ' + visit.date.toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true })
        visit.time = visit.time / 1000
        // round time to nearest tenth of a second
        visit.time = Math.round(visit.time * 10) / 10
        if (visit.bytes < 1000) {
          visit.bytes = `${visit.bytes} B`
        } else if (visit.bytes < 1000000) {
          visit.bytes = `${Math.round(visit.bytes / 100) / 10} KB`
        } else if (visit.bytes < 1000000000) {
          visit.bytes = `${Math.round(visit.bytes / 100000) / 10} MB`
        } else {
          visit.bytes = `${Math.round(visit.bytes / 100000000) / 10} GB`
        }
      });
      return data
    },
    reformatDetails(data) {
      data.forEach(visit => {
        visit.date = new Date(visit.date)
        // don't display seconds
        visit.date = visit.date.toLocaleString().replace(',', '')
        visit.time = visit.time / 1000
        // round time to nearest tenth of a second
        visit.time = Math.round(visit.time * 10) / 10
        if (visit.bytes < 1000) {
          visit.bytes = `${visit.bytes} B`
        } else if (visit.bytes < 1000000) {
          visit.bytes = `${Math.round(visit.bytes / 100) / 10} KB`
        } else if (visit.bytes < 1000000000) {
          visit.bytes = `${Math.round(visit.bytes / 100000) / 10} MB`
        } else {
          visit.bytes = `${Math.round(visit.bytes / 100000000) / 10} GB`
        }
      });
      return data
    },
    focusOnVisit(visitId, ip, app) {
      // console.log(`visitId: ${visitId}`)
      console.log(this.altDown)
      if (!this.altDown) {
        fetch(`https://demo10.lincolnnguyen18.com/getDetails?visitId=${visitId}`)
          .then(res => res.json())
          .then(data => {
            data = this.reformatDetails(data)
            console.log(data)
            this.details = data
            data.forEach(detail => {
              detail.ip = ip
              detail.app = app
            })
            this.setMode('focus')
          })
      } else {
        this.openIp(ip)
        this.altDown = false
      }
    },
    focusSearch() {
      if (!this.searchFocused) {
        this.searchFocused = true
        this.$refs.searchInput.focus()
      } else {
        this.searchFocused = false
        this.$refs.searchInput.blur()
      }
    },
    openIp(ip) {
      console.log(`opening ip: ${ip}`)
      window.open(`https://ipinfo.io/${ip}`)
    },
    loadVisits: async function () {
      await fetch(`https://demo10.lincolnnguyen18.com/getVisits?search=${this.search}`)
      .then(response => response.json())
      .then(data => {
        data = this.reformatVisits(data)
        console.log(data)
        this.visitors = data
      })
    },
    checkEmptySearch() {
      if (this.search === '') {
        this.loadVisits()
      }
    },
    refresh: async function () {
      this.refreshing = true
      setTimeout(async () => {
        await this.loadVisits()
        this.refreshing = false
        this.$refs.table.scrollTop = 0
      }, 1000)
    }
  },
  mounted() {
    this.loadVisits();
    // listen for escape
    document.addEventListener('keyup', e => {
      if (e.key == 'Escape') {
        this.setMode('all')
      } else if (e.key == 'Alt') {
        this.altDown = false
      }
    })
    document.addEventListener('keydown', e => {
      if (e.key == 'Alt') {
        this.altDown = true
      }
    })
  },
  components: { Loading }
}
</script>

<template>
<div class="search" ref="search" :class="{'focus-search': searchFocused}">
  <span class="material-icons-round search-button" @click="loadVisits">search</span>
  <input type="search" placeholder="Search" v-model="search" @keyup.enter="loadVisits" @submit.prevent="loadVisits" @input="checkEmptySearch" @focus="focusSearch" @blur="focusSearch" ref="searchInput">
  <span class="material-icons-round search-button" @click="clearSearch" ref="clear" :class="{'hidden': search === ''}">close</span>
</div>
<div class="all" v-show="mode == 'all'">
  <div class="table-row table-header">
    <span>
      Date
      <span class="material-icons-outlined">arrow_drop_down</span>
    </span>
    <span>IP</span>
    <span>App</span>
    <span>Time (s)</span>
    <span>Size</span>
    <span>
      Country
      <!-- <span class="material-icons-outlined">arrow_drop_down</span> -->
    </span>
    <span>Region</span>
    <span>City</span>
    <span class="material-icons-round refresh" @click="refresh" v-if="!refreshing">refresh</span>
    <Loading size=20 borderThickness=3 v-if="refreshing" class="refreshing" />
  </div>
  <div class="table-rows" @scroll="onScroll" ref="table">
    <div class="table-row table-row-only" v-for="visitor in visitors" :key="visitor.id" @click="focusOnVisit(visitor.id, visitor.ip, visitor.app)">
      <span>{{visitor.date}}</span>
      <span>{{visitor.ip}}</span>
      <span>{{visitor.app}}</span>
      <span>{{visitor.time}}</span>
      <span>{{visitor.bytes}}</span>
      <span>{{visitor.country}}</span>
      <span>{{visitor.region}}</span>
      <span>{{visitor.city}}</span>
    </div>
  </div>
</div>
<div class="focus" v-show="mode == 'focus'">
  <div class="table-row table-header">
    <span>Date</span>
    <span>IP</span>
    <span>App</span>
    <span>Time (s)</span>
    <span>Size</span>
    <span>Path</span>
    <span class="material-icons-outlined close" @click="setMode('all')">close</span>
  </div>
  <div class="table-rows">
    <div class="table-row table-row-only" v-for="detail in details" :key="detail.id">
      <span>{{detail.date}}</span>
      <span class="ip" @click="openIp(detail.ip)">{{detail.ip}}</span>
      <span>{{detail.app}}</span>
      <span>{{detail.time}}</span>
      <span>{{detail.bytes}}</span>
      <span class="path">{{detail.path}}</span>
    </div>
  </div>
</div>
</template>

<style scoped>
.search {
  background: #EFEFEF;
  border-radius: 7px;
  width: 540px;
  height: 42px;
  display: flex;
  align-items: center;
}
.search input {
  font-size: 16px;
  background: none;
  border: none;
  width: auto;
  height: 100%;
  width: 100%;
  padding: 10px;
  padding-left: 0;
  border-radius: 7px;
  color: #333;
  outline: none;
}
input[type="search"]::-webkit-search-decoration,
input[type="search"]::-webkit-search-cancel-button,
input[type="search"]::-webkit-search-results-button,
input[type="search"]::-webkit-search-results-decoration {
  -webkit-appearance:none;
}
.hidden {
  visibility: hidden;
}
.search span {
  font-size: 28px;
  user-select: none;
  cursor: pointer;
  width: 60px;
  text-align: center;
  color: #333;
}
.table-header {
  font-weight: bold;
  margin-top: 30px;
  margin-bottom: 10px;
  height: 30px;
}
.table-header span {
  display: flex;
  align-items: center;
}
.table-row {
  display: grid;
  padding: 0 24px;
  gap: 16px;
  width: 1100px;
}
.all, .focus {
  height: calc(100% - 250px);
}
.all .table-row-only {
  user-select: none;
  cursor: pointer;
}
.all .table-row {
  grid-template-columns: 180px 140px 200px 70px 80px 120px 60px auto auto;
}
.focus .table-row {
  grid-template-columns: 180px 140px 200px 70px 80px auto auto;
}
.focus .ip {
  cursor: pointer;
}
.ip {
  z-index: 2;
}
.table-rows .table-row:hover {
  background: #EFEFEF;
}
.table-row-only {
  padding-top: 10px;
  padding-bottom: 10px;
  border-bottom: 1px solid #efefef;
}
.table-row:last-child {
  border-bottom: none;
}
.table-rows {
  height: 100%;
  margin-bottom: 28px;
  overflow: auto;
  background: #FFFFFF;
  box-shadow: inset 0px 4px 4px rgba(0, 0, 0, 0.25);
  border-radius: 7px;
  padding: 6px 0px;
}
.refresh:hover, .search-button:hover, .close:hover {
  color: #808080;
}
.close {
  justify-self: flex-end;
  user-select: none;
  cursor: pointer;
}
.refresh {
  justify-self: flex-end;
  user-select: none;
  cursor: pointer;
}
.refreshing {
  justify-self: flex-end;
  align-self: center;
}
.path {
  word-break: break-all;
}
.focus-search {
  background: #ffffff;
  transition: background 0.2s;
  outline: 1px solid #bbb;
}
</style>
