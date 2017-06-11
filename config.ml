open Mirage

let main =
  let packages = [
    package "mirage-qubes";
    package "io-page" ~sublibs:["xen"];
  ] in
  foreign
    ~packages
    "Unikernel.Main" (qubesdb @-> stackv4 @-> time @-> job)

let () =
  register "qubes-skeleton" ~argv:no_argv [
    main $ default_qubesdb $ qubes_ipv4_stack default_network $ default_time
  ]
