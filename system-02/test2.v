Require Import List.
Require Import ZArith.
Require Import PeanoNat.
Open Scope Z_scope.

(* ==========================================
   MODULE 1: SpaceWire Protocol Definitions
   ========================================== *)
Module SpaceWire_Protocol.
  Inductive RMAP_Command :=

    | RMAP_Read (addr : Z) (length : Z)
    | RMAP_Write (addr : Z) (data : list Z).

  Inductive Packet :=

    | RMAP_Packet (cmd : RMAP_Command)
    | RMAP_Reply (payload : list Z)
    | EEP (error_code : Z).

  Inductive Op (Next : Type) : Type :=

    | SendPacket (p : Packet) (k : Next)
    | ReceivePacket (k : Packet -> Next).

  Arguments SendPacket {Next}.
  Arguments ReceivePacket {Next}.

  Inductive Free (A : Type) : Type :=

    | Pure (a : A)
    | Impure (op : Op (Free A)).

  Arguments Pure {A}.
  Arguments Impure {A}.

  Fixpoint bind {A B : Type} (m : Free A) (f : A -> Free B) : Free B :=
    match m with

    | Pure a => f a
    | Impure (SendPacket p k) => Impure (SendPacket p (bind k f))
    | Impure (ReceivePacket k) => Impure (ReceivePacket (fun p => bind (k p) f))
    end.
End SpaceWire_Protocol.

Import SpaceWire_Protocol.
Notation "x >>= f" := (bind x f) (at level 50, left associativity).

(* ==========================================
   MODULE 2: Computer Software Logic
   ========================================== *)
Module ComputerLogic.
  Definition send p := Impure (SendPacket p (Pure tt)).
  Definition recv   := Impure (ReceivePacket (fun p => Pure p)).

  (* Task: Write 1 to Config (Addr 0), then Read X-axis (Addr 10) *)
  Definition setup_and_read_x : Free (list Z) :=
    send (RMAP_Packet (RMAP_Write 0 (1 :: nil))) >>= (fun _ =>
    send (RMAP_Packet (RMAP_Read 10 1)) >>= (fun _ =>
    recv >>= (fun resp =>
      match resp with

      | RMAP_Reply val => Pure val
      | _ => Pure ((-1) :: nil)
      end))).
End ComputerLogic.

(* ==========================================
   MODULE 3: Hardware Simulation
   ========================================== *)
Module HardwareSimulation.
  Record GyroState := {
    x_reg   : Z;
    y_reg   : Z;
    config  : Z;
    pending : Z
  }.

  Fixpoint run (n : nat) (prog : Free (list Z)) (s : GyroState) : (list Z * GyroState) :=
    match n with

    | O => (nil, s)
    | S n' =>
        match prog with

        | Pure result => (result, s)
        | Impure (SendPacket p k) =>
            match p with

            | RMAP_Packet (RMAP_Write addr data) =>
                let next_s := {| x_reg := s.(x_reg); 
                                 y_reg := s.(y_reg); 
                                 config := (if addr =? 0 then hd 0 data else s.(config));
                                 pending := s.(pending) |} in
                run n' k next_s

            | RMAP_Packet (RMAP_Read addr len) =>
                let next_s := {| x_reg := s.(x_reg); 
                                 y_reg := s.(y_reg); 
                                 config := s.(config); 
                                 pending := addr |} in
                run n' k next_s

            | _ => run n' k s (* Ignore replies/errors sent by computer *)
            end
        | Impure (ReceivePacket k) => 
            let val := if s.(pending) =? 10 then s.(x_reg) else s.(y_reg) in
            (* If config is 1, simulate high precision by multiplying by 100 *)
            let final_val := if s.(config) =? 1 then val * 100 else val in
            run n' (k (RMAP_Reply (final_val :: nil))) s
        end
    end.
End HardwareSimulation.

(* ==========================================
   EXECUTION
   ========================================== *)

(* Initial hardware: X=42, Y=88, Config=0 *)
Definition initial_gyro := 
  {| HardwareSimulation.x_reg := 42; 
     HardwareSimulation.y_reg := 88; 
     HardwareSimulation.config := 0; 
     HardwareSimulation.pending := 0 |}.

(* Run the program with 20 steps of "gas" *)
Compute (HardwareSimulation.run 20 ComputerLogic.setup_and_read_x initial_gyro).

(* 
   EXPECTED RESULT:
   = ([4200], {| x_reg := 42; y_reg := 88; config := 1; pending := 10 |})
*)

