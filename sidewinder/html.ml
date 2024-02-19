type 'msg attr =
  [ `event of string * (string -> 'msg) | `attr of string * string ]

let event name fn = `event (name, fn)
let on_click fn = event "click" fn
let attr name value = `attr (name, value)
let attr_id v = attr "id" v
let attr_type v = attr "type" v
let attr_src v = attr "src" v

type 'msg t =
  | El of { tag : string; attrs : 'msg attr list; children : 'msg t list }
  | Text of string
  | Splat of 'msg t list

let list els = Splat els

let button ~on_click ?(children = []) () =
  El { tag = "button"; attrs = [ on_click ]; children }

let html ?(children = []) () = El { tag = "html"; attrs = []; children }
let body ?(children = []) () = El { tag = "body"; attrs = []; children }

let div ?(attrs = []) ?id ?(children = []) () =
  El
    {
      tag = "div";
      attrs =
        List.filter_map Fun.id [ Option.map attr_id id ]
        @ List.map (fun (k, v) -> `attr (k, v)) attrs;
      children;
    }

let h1 ?(children = []) () = El { tag = "h1"; attrs = []; children }
let h2 ?(children = []) () = El { tag = "h2"; attrs = []; children }
let h3 ?(children = []) () = El { tag = "h3"; attrs = []; children }
let h5 ?(children = []) () = El { tag = "h4"; attrs = []; children }
let h6 ?(children = []) () = El { tag = "h5"; attrs = []; children }
let span ?(children = []) () = El { tag = "span"; attrs = []; children }
let p ?(children = []) () = El { tag = "p"; attrs = []; children }

let script ?src ?id ?type_ ?(children = []) () =
  El
    {
      tag = "script";
      attrs =
        [
          Option.map attr_id id;
          Option.map attr_type type_;
          Option.map attr_src src;
        ]
        |> List.filter_map Fun.id;
      children;
    }

let string (str : string) = Text str
let int (x : int) = Text (Int.to_string x)

let rec to_string (t : 'msg t) =
  match t with
  | Text str -> str
  | Splat els -> String.concat "\n" (List.map to_string els)
  | El { tag; children; attrs } ->
      "<" ^ tag ^ " " ^ attrs_to_string attrs ^ ">"
      ^ (List.map to_string children |> String.concat "\n")
      ^ "</" ^ tag ^ ">"

and attrs_to_string attrs =
  List.map
    (function `attr (k, v) -> Format.sprintf "%s=%S" k v | _ -> "")
    attrs
  |> String.concat " "

let event_handlers attrs =
  List.filter_map
    (fun attr ->
      match attr with `event (name, fn) -> Some (name, fn) | _ -> None)
    attrs

let rec map_action fn t =
  match t with
  | Text string -> Text string
  | Splat els -> Splat (List.map (map_action fn) els)
  | El { tag; children; attrs } ->
      let children = List.map (map_action fn) children in
      let attrs =
        List.map
          (fun attr ->
            match attr with
            | `event (name, handler) -> `event (name, fun ev -> fn (handler ev))
            | `attr (k, v) -> `attr (k, v))
          attrs
      in
      El { tag; children; attrs }
