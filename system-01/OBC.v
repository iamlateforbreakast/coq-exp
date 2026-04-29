(* OBC.v *)
Require Import SpaceWireProject.SpaceWireBase.

Record OBC_State := {
  link_status : SpW_State;
  commands_sent : nat
}.

Definition obc_behaviour : SpW_IO unit :=
  Read (fun (s : SpW_Signal) => @Return tt).
