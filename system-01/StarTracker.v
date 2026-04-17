(* StartTracker.v *)
Require Import SpaceWireBase.

Record STR_STate := {
  link_status : SpW_State;
  current_quat : nat
}.

Definition str_behaviour : SpW_IO unit :=
  Write (Signal_Data 42) (Return tt).
