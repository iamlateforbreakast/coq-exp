(* OBC.v *)
Require Import SpaceWireBase.

Record OBC_State := {
  link_status : SpW_State;
  commands_sent : nat
}.

Definition obc_behaviour : SpW_IO unit :=
  s <- Read (fun s => Return s) ;; Return tt.
