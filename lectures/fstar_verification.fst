module Fstar_verification

open FStar.Mul

(** There are two approaches to verification in F*
    
    (1) Intrinsically at definition time
    (2) Extrinsically through SMT-backed lemmas

    We have already seen several examples of intrinsic verification.
*)

val factorial : nat -> Tot nat              (* type nat = x:int{x >= 0} *)
let rec factorial n = 
  if n = 0 then 1 else n * factorial (n-1)

(* We can also equivalently write pre- and post-conditions for this *)

val factorial2 : x : int -> Pure int (requires (x >= 0))
                               (ensures (fun y -> y >= 0))
let rec factorial2 n =
  if n = 0 then 1 else n * factorial2 (n-1)

(* In fact, [Tot] is essentially just an abbreviation:

   [Tot t = Pure t (requires True) (ensures (fun _ -> True))]

   Similarly, [Dv] is just an abbreviation for:

   [Dv t = Div t (requires True) (ensures (fun _ -> True))]
*)

(******************************************************************************)

(** A high-level view of types in F* 

    You can view types in F* as belonging to two "kinds"

    * Value types (V) -- int, int list, ...
    * Computation types (C) -- Tot t, Dv t, ...

    Types can also be refined:

    * Refined value types -- x:t{p}
    * Refined computation types
      + Pure t pre post
      + Div t pre post
      
    Dependent functions are of the form 

    [x0:t0 -> ... -> xn:tn{x1...xn-1} -> C ]

    where the notation {x1...xn-1} sal2 that the variables x1 to xn-1 may appear
    free in the refinement.
*)

(******************************************************************************)

(* Intrinsically verifying append *)

val length : list 'a -> Tot nat
let rec length l = 
  match l with
  | [] -> 0
  | _::ls -> length ls + 1

val append : l1:list 'a -> l2:list 'a -> l3:list 'a{length l3 = length l1 + length l2}
let rec append l1 l2 =
  match l1 with
  | [] -> l2
  | x::xs -> x::(append xs l2)

(* Extrinsically verifying append 

   We can under specify the type of [append] and verify the fact about length as
   a separate lemma.

*)

val append2 : list 'a -> list 'a -> list 'a
let rec append2 l1 l2 =
  match l1 with
  | [] -> l2
  | x::xs -> x::(append2 xs l2)

val append_len : 
  l1:list 'a -> l2:list 'a -> 
  Pure unit (requires True) 
            (ensures (fun _ -> length (append2 l1 l2) = length l1 + length l2))
let rec append_len l1 l2 =
  match l1 with
  | [] -> ()
  (* To show: length (append2 [] l2) = length [] + length l2 *)
  (* Still to show after computation: length l2 = 0 + length l2 *)

  | x::xs -> append_len xs l2
  (* Know recursive call's postcondition (rec_post): length (app xs l2) = length xs + length l2  *)
  (* To show: len (append2 (x::xs) l2) = length (x::xs) + length l2 *)
  (* Simplify: 1 + len (append2 xs l2) = (1 + length xs) + length l2 *)
  (* Still to show: rec_post ==> 1 + length (append2 xs l2) = (1 + length xs) + length l2 *)

(** Lemma Syntactic Sugar

    Lemma (post) = Pure unit (requires True) (ensures (fun _ -> post))
    Lemma (pre) (post) = Pure unit (requires pre) (ensures (fun _ -> post))

*)

let rec append_len2 (l1 l2 : list 'a) :
  Lemma (length (append2 l1 l2) = length l1 + length l2) =
  match l1 with
  | [] -> ()
  | x::xs -> append_len2 xs l2
