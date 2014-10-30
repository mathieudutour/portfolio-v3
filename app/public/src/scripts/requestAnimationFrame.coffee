###
# Request Animation Frame Polyfill.
# @author Tino Zijdel
# @author Paul Irish
# @see https://gist.github.com/paulirish/1579671
###

lastTime = 0
vendors = ['ms', 'moz', 'webkit', 'o']

for vendor in vendors
  do (vendor) ->
    window.requestAnimationFrame = window[vendor+'RequestAnimationFrame']
    window.cancelAnimationFrame = window[vendor+'CancelAnimationFrame'] ||
      window[vendor+'CancelRequestAnimationFrame']

if !window.requestAnimationFrame
  window.requestAnimationFrame = (callback, element) ->
    currTime = new Date().getTime()
    timeToCall = Math.max(0, 16 - (currTime - lastTime))
    id = window.setTimeout(
      () ->
        callback(currTime + timeToCall)
    , timeToCall )
    lastTime = currTime + timeToCall
    return id;

if !window.cancelAnimationFrame
  window.cancelAnimationFrame = (id) ->
    clearTimeout(id)
