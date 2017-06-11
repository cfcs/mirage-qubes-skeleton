(* Copyright (C) 2016, Thomas Leonard
   See the README file for details. *)

open Lwt
open Qubes

let src = Logs.Src.create "unikernel" ~doc:"Main unikernel code"
module Log = (val Logs.src_log src : Logs.LOG)

module Main
    (DB : Qubes.S.DB)
    (Stack : Mirage_stack_lwt.V4)
    (Time : Mirage_time_lwt.S) = struct

  let get_required qubesDB key =
    match DB.read qubesDB key with
    | None -> failwith (Printf.sprintf "Required QubesDB key %S not found" key)
    | Some v ->
      Log.info (fun f -> f "QubesDB %S = %S" key v);
      v

  let start qubesDB stack _time =
    Log.info (fun f -> f "Starting");
    (* Start qrexec agent and GUI agent in parallel *)
    let qrexec = RExec.connect ~domid:0 () in
    let gui = GUI.connect ~domid:0 () in
    (* Wait for clients to connect *)
    qrexec >>= fun qrexec ->
    let agent_listener = RExec.listen qrexec Command.handler in
    gui >>= fun gui ->
    Lwt.async (fun () -> GUI.listen gui);
    Lwt.async (fun () ->
      OS.Lifecycle.await_shutdown_request () >>= fun (`Poweroff | `Reboot) ->
      RExec.disconnect qrexec
    );
    Log.info (fun f -> f "Network test done. Waiting for qrexec commands...");
    agent_listener
end
