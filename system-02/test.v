Require Import String.
Require Import List.
Require Import ZArith.
Open Scope string_scope.
Open Scope Z_scope.

(* --- 1. SpaceWire Data Structures --- *)

(* A SpaceWire Packet is a list of bytes (Z) followed by an End of Packet marker *)
Inductive SpW_Packet :=

  | Packet (payload : list Z)
  | EEP (error_code : Z). (* Error End of Packet for failures *)

(* --- 2. Defining the IO Operations (The "Bus") --- *)

Inductive SpW_Op (Next : Type) : Type :=

  | SendPacket (p : SpW_Packet) (k : Next)
  | ReceivePacket (k : SpW_Packet -> Next).

Arguments SendPacket {Next}.
Arguments ReceivePacket {Next}.

(* --- 3. The Free Monad --- *)

Inductive Free (A : Type) : Type :=

  | Pure (a : A)
  | Impure (op : SpW_Op (Free A)).

Arguments Pure {A}.
Arguments Impure {A}.

Definition bind {A B : Type} (m : Free A) (f : A -> Free B) : Free B :=
  (fix loop m :=
    match m with

    | Pure a => f a
    | Impure (SendPacket p k) => Impure (SendPacket p (loop k))
    | Impure (ReceivePacket k) => Impure (ReceivePacket (fun p => loop (k p)))
    end) m.

Notation "x >>= f" := (bind x f) (at level 50, left associativity).

(* Helpers *)
Definition send (p : SpW_Packet) : Free unit := Impure (SendPacket p (Pure tt)).
Definition receive : Free SpW_Packet := Impure (ReceivePacket (fun p => Pure p)).

(* --- 4. The Computer Program --- *)

(* The computer sends a "Read Command" (0x01) and waits for 3 values from the gyro *)
Definition read_gyro_telemetry : Free (list Z) :=
  send (Packet (1 :: nil)) >>= (fun _ =>
  receive >>= (fun resp =>
    match resp with

    | Packet data => Pure data
    | EEP _ => Pure (0 :: 0 :: 0 :: nil) (* Default on error *)
    end)).

(* --- 5. The Hardware Simulator --- *)

(* This simulates the physical Gyroscope reacting to packets on the wire *)
Fixpoint hardware_bus (prog : Free (list Z)) (gyro_state : list Z) : list Z :=
  match prog with

  | Pure result => result
  | Impure (SendPacket (Packet (cmd :: nil)) k) =>
      if cmd =? 1 then (* Gyro receives Read command *)
        hardware_bus k gyro_state
      else hardware_bus k gyro_state

  | Impure (ReceivePacket k) => 
      (* Gyro sends its current X, Y, Z state back *)
      hardware_bus (k (Packet gyro_state)) gyro_state
  | _ => nil
  end.

(* --- 6. Execution --- *)

(* Simulate a Gyro currently at X=10, Y=-5, Z=100 *)
Definition current_gyro_hardware := (10 :: -5 :: 100 :: nil).

Compute (hardware_bus read_gyro_telemetry current_gyro_hardware).
(* Result: [10; -5; 100] *)

