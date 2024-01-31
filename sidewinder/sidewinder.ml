open Riot
open Trail

open Riot.Logger.Make (struct
  let namespace = [ "sidewinder" ]
end)

module Html = Html

module Event = struct
  open Serde

  type t = string [@@deriving deserializer, serializer]
end

type Message.t += Render of string

module type Intf = sig
  type args
  type state
  type action

  val init : args -> state
  val handle_action : state -> action -> state
  val render : state -> action Html.t
end

module Default = Sidewinder_default

module Component = struct
  type ('args, 'state, 'action) t = {
    ref : 'action Ref.t;
    state : 'state;
    handle_action : 'state -> 'action -> 'state;
    render : 'state -> 'action Html.t;
    handlers : (string, Event.t -> 'action) Hashtbl.t;
    renderer : Pid.t;
  }

  type Message.t +=
    | Mount
    | Event of { id : string; event : Event.t }
    | Dispatch : 'action Ref.t * 'action -> Message.t

  let render t html =
    let str = Html.to_string html in
    error (fun f -> f " rendering: %S" str);
    send t.renderer (Render str)

  let rec update_handlers ?(idx = 0) t (html : 'action Html.t) =
    match html with
    | Html.Text _ -> html
    | Html.El { tag; attrs; children } ->
        error (fun f -> f "found tag %S with %d attrs" tag (List.length attrs));
        let attrs =
          match Html.event_handlers attrs with
          | [] -> attrs
          | handlers ->
              let attrs = ref attrs in
              List.iteri
                (fun n handler ->
                  let id =
                    "sidewinder-handler-" ^ Int.to_string idx ^ "-"
                    ^ Int.to_string n
                  in
                  error (fun f -> f "found handler %S" id);
                  Hashtbl.replace t.handlers id handler;
                  attrs := `attr ("data-sidewinder-id", id) :: !attrs;
                  ())
                handlers;
              !attrs
        in
        let children = List.mapi (fun idx -> update_handlers ~idx t) children in
        Html.El { tag; attrs; children }

  let rec loop (t : ('args, 'state', 'action) t) =
    match receive () with
    | Mount -> handle_mount t
    | Event { id; event } -> handle_event t id event
    | Dispatch (ref, action) -> (
        match Ref.cast ref t.ref action with
        | Some action -> handle_action t action
        | None -> failwith "bad message")
    | _ -> loop t

  and handle_action t action =
    error (fun f -> f "%a is handling action" Pid.pp (self ()));
    let state = t.handle_action t.state action in
    let html = t.render state in
    let html = update_handlers t html in
    render t html;
    loop { t with state }

  and handle_event t id event =
    error (fun f -> f "%a is handling event" Pid.pp (self ()));
    match Hashtbl.find_opt t.handlers id with
    | None -> loop t
    | Some handler ->
        let action = handler event in
        send (self ()) (Dispatch (t.ref, action));
        loop t

  and handle_mount t =
    error (fun f -> f "%a is mounting" Pid.pp (self ()));
    let html = t.render t.state in
    let html = update_handlers t html in
    render t html;
    loop t

  let start_link (type args) renderer (module C : Intf with type args = args)
      (args : args) =
    let pid =
      spawn_link (fun () ->
          loop
            {
              ref = Ref.make ();
              renderer;
              state = C.init args;
              handle_action = C.handle_action;
              render = C.render;
              handlers = Hashtbl.create 0;
            })
    in
    Ok pid

  let mount pid = send pid Mount
  let event pid id event = send pid (Event { id; event })
end

open Serde

type event = Mount | Event of string * Event.t | Patch of string
[@@deriving deserializer, serializer]

module Mount (C : Intf) = struct
  include Sock.Default

  type args = C.args
  type state = { component : Pid.t }

  let init args =
    let this = self () in
    let component =
      Component.start_link this (module C) args |> Result.get_ok
    in
    `ok { component }

  let handle_frame (frame : Frame.t) _conn state =
    match frame with
    | Frame.Text { payload; _ } -> (
        error (fun f -> f "got event: %S" payload);
        match Serde_json.of_string deserialize_event payload with
        | Ok (Event (id, event)) ->
            Component.event state.component id event;
            `ok state
        | Ok Mount ->
            Component.mount state.component;
            `ok state
        | Ok _ -> `ok state
        | Error err ->
            error (fun f ->
                f "could not deserialize frame: %S" (Marshal.to_string err []));
            `ok state)
    | Frame.Ping -> `push ([ Frame.pong ], state)
    | _ -> `ok state

  let handle_message msg state =
    error (fun f -> f "handle_message");
    match msg with
    | Render html ->
        error (fun f -> f "rendering: %S" html);
        let event =
          Serde_json.to_string_pretty serialize_event (Patch html)
          |> Result.get_ok
        in
        let frame = Frame.text ~fin:true event in
        `push ([ frame ], state)
    | _ -> `ok state
end
