(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)


type region
[@@deriving (eq, show)]

(** The name an error message shows for the region: `Static`, the region name a
    `borrow` statement declares, or `region of the borrow of <variable>` for an
    anonymous borrow. *)
val region_name : region -> Identifier.identifier

val static_region : region

(** A region no other borrow has, with the name an error message shows for it, and the
    supply to take the next one from. *)
val fresh_region : Identifier.identifier -> Supply.t -> region * Supply.t
