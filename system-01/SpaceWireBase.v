(* SpaceWireBase.v *)

Inductive SpW_Signal :=

  | Signal_FCT | Signal_EOP | Signal_Data (d : nat).

Inductive SpW_State := ErrorReset | Run. (* Simplified *)

Inductive SpW_IO (A : Type) : Type :=

  | Return : A -> SpW_IO A
  | Read   : (SpW_Signal -> SpW_IO A) -> SpW_IO A
  | Write  : SpW_Signal -> SpW_IO A -> SpW_IO A.
