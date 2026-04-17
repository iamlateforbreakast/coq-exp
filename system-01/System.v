(* System.v *)
Require Import SpaceWireBase.
Require Import StarTracker.
Require Import OBC.

Record SystemState := {
  str_node : STR_state;
  str_io   : SpW_IO unit;
  obc_node : OBC_State;
  obc_io   : SpW_IO unit
}.
