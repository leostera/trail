(lang dune 3.10)

(name trail)

(generate_opam_files true)

(source
 (github leostera/trail))

(authors "Leandro Ostera <leandro@abstractmachines.dev>")

(maintainers "Leandro Ostera <leandro@abstractmachines.dev>")

(license MIT)

(package
 (name trail)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
  (ocaml
   (>= "5.1.0"))
  riot
  atacama
  http
  httpaf
  (calendar (>= "3.0.0"))
  (bitstring (>= "4.1.0"))
  (ppx_bitstring (>= "4.1.0"))
  (uuidm
   (>= "0.9.8")))
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
