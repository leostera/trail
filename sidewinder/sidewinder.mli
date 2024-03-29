module Html : sig
  type 'msg attr =
    [ `attr of string * string | `event of string * (string -> 'msg) ]

  val attr : string -> string -> 'msg attr
  val attr_id : 'a -> [> `attr of string * 'a ]
  val attr_type : 'a -> [> `attr of string * 'a ]

  type 'msg t =
    | El of { tag : string; attrs : 'msg attr list; children : 'msg t list }
    | Text of string
    | Splat of 'msg t list

  val list : 'msg t list -> 'msg t
  val button : on_click:'a attr -> ?children:'a t list -> unit -> 'a t
  val html : ?children:'a t list -> unit -> 'a t
  val body : ?children:'a t list -> unit -> 'a t

  val div :
    ?attrs:(string * string) list ->
    ?id:string ->
    ?children:'a t list ->
    unit ->
    'a t

  val span : ?children:'a t list -> unit -> 'a t

  val script :
    ?src:string ->
    ?id:string ->
    ?type_:string ->
    ?children:'a t list ->
    unit ->
    'a t

  val event : string -> (string -> 'msg) -> 'msg attr
  val string : string -> 'a t
  val int : int -> 'a t
  val to_string : 'msg t -> string
  val attrs_to_string : 'msg attr list -> string
  val event_handlers : 'msg attr list -> (string * (string -> 'msg)) list
  val map_action : ('msg_a -> 'msg_b) -> 'msg_a t -> 'msg_b t
  val on_click : (string -> 'msg) -> 'msg attr
end

module type Intf = sig
  type state
  type action

  val mount : Trail.Conn.t -> state
  val handle_action : state -> action -> state
  val render : state:state -> unit -> action Html.t
end

module Default : sig
  val mount : path:string -> unit -> 'action Html.t
end

module Mount : functor (_ : Intf) -> sig
  type state = { component : Riot.Pid.t }

  val init : unit -> [> `ok of state ]

  val handle_frame :
    Trail.Frame.t ->
    'a ->
    state ->
    [> `ok of state | `push of Trail.Frame.t list * state ]

  val handle_message :
    Riot.Message.t -> 'a -> [> `ok of 'a | `push of Trail.Frame.t list * 'a ]
end

module Static : sig
  type args = unit
  type state = unit

  val init : unit -> unit
  val call : Trail.Conn.t -> unit -> Trail.Conn.t
end

val live : string -> (module Intf) -> Trail.Router.t
