// Generated by Melange


var $$Event = {};

var $$WebSocket = {};

var $$Element = {};

var $$Document = {};

function mount(socket, _event) {
  socket.send(" \"Mount\" ");
}

var $$event = (function (element, event) {
  let id = element.getAttribute("data-sidewinder-id");
  return JSON.stringify({ "Event": [id, ""] })
});

function handle_click(socket, el, e) {
  socket.send($$event(el, e));
}

var rebind = (function (socket, element) { 
  let elements = [...element.querySelectorAll("*[data-sidewinder-id]")];
  elements.forEach((el) => {
    el.addEventListener("click", (ev) => handle_click(socket, el, ev));
  });
});

var patch = (function (event) {
let json = JSON.parse(event.data);
return json.Patch[0]
});

function handle_event(socket, element, e) {
  var diff = patch(e);
  element.innerHTML = diff;
  return rebind(socket, element);
}

function spawn(element_id, path) {
  var element = document.getElementById(element_id);
  var url = "ws://192.168.1.19:8080" + path;
  var socket = new WebSocket(url);
  socket.addEventListener("open", (function (param) {
          return mount(socket, param);
        }));
  socket.addEventListener("message", (function (param) {
          return handle_event(socket, element, param);
        }));
}

export {
  $$Event ,
  $$WebSocket ,
  $$Element ,
  $$Document ,
  mount ,
  $$event ,
  handle_click ,
  rebind ,
  patch ,
  handle_event ,
  spawn ,
}
/* No side effect */
