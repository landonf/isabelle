(* ========================================================================= *)
(* PRESERVING SHARING OF ML VALUES                                           *)
(* Copyright (c) 2005-2006 Joe Hurd, distributed under the BSD License       *)
(* ========================================================================= *)

signature Sharing =
sig

(* ------------------------------------------------------------------------- *)
(* Option operations.                                                        *)
(* ------------------------------------------------------------------------- *)

val mapOption : ('a -> 'a) -> 'a option -> 'a option

val mapsOption : ('a -> 's -> 'a * 's) -> 'a option -> 's -> 'a option * 's

(* ------------------------------------------------------------------------- *)
(* List operations.                                                          *)
(* ------------------------------------------------------------------------- *)

val map : ('a -> 'a) -> 'a list -> 'a list

val revMap : ('a -> 'a) -> 'a list -> 'a list

val maps : ('a -> 's -> 'a * 's) -> 'a list -> 's -> 'a list * 's

val revMaps : ('a -> 's -> 'a * 's) -> 'a list -> 's -> 'a list * 's

val updateNth : int * 'a -> 'a list -> 'a list

val setify : ''a list -> ''a list

(* ------------------------------------------------------------------------- *)
(* Function caching.                                                         *)
(* ------------------------------------------------------------------------- *)

val cache : ('a * 'a -> order) -> ('a -> 'b) -> 'a -> 'b

(* ------------------------------------------------------------------------- *)
(* Hash consing.                                                             *)
(* ------------------------------------------------------------------------- *)

val hashCons : ('a * 'a -> order) -> 'a -> 'a

end
