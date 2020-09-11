// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import { Socket } from "phoenix"
import NProgress from "nprogress"
import { LiveSocket } from "phoenix_live_view"

let Hooks = {}

Hooks.ScrollToTrack = {
  mounted() {
    this.handleEvent("scroll_to_playing_track", ({ track_idx }) => {
      var track_div = document.getElementById(`track_${track_idx}`);
      track_div.scrollIntoView();
    })

    this.el.addEventListener("scroll", (e) => {
      this.pushEvent("playlist_scroll_detected")
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  metadata: {
    click: (e, el) => {
      let elementRect = el.getBoundingClientRect();
      let elementMinX = elementRect.x;
      let elementMaxX = elementRect.x + elementRect.width;
      let elementMinY = elementRect.y;
      let elementMaxY = elementRect.y + elementRect.height;

      return {
        clientX: e.clientX,
        clientY: e.clientY,
        elementMinX: elementMinX,
        elementMaxX: elementMaxX,
        elementMinY: elementMinY,
        elementMaxY: elementMaxY,
      }
    }
  }
})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
