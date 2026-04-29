Require Import Coq.Init.Datatypes.

Inductive SpW_IO (A : Type) : Type :=
  | Return : A -> SpW_IO A.

Definition str_behaviour : SpW_IO unit := Return tt.
