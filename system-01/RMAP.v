Require Import List ZArith String.
Import ListNotations.

(* RMAP configuration types *)
Record RMAP_Addr := { logical_addr : Z; memory_addr : Z }.

Inductive RMAP_ops : Type -> Type :=

  | RMAP_Read  : RMAP_Addr -> Z -> RMAP_ops (list Z) (* Addr, Length -> Data *)
  | RMAP_Write : RMAP_Addr -> list Z -> bool -> RMAP_ops Z (* Addr, Data, Verify -> Status *)
  | RMAP_RMW   : RMAP_Addr -> Z -> Z -> RMAP_ops Z. (* Addr, Data, Mask -> OldValue *)

Inductive RMAP (A : Type) : Type :=
  | Pure : A -> RMAP A
  | Call : forall T, RMAP_ops T -> (T -> RMAP A) -> RMAP A.



