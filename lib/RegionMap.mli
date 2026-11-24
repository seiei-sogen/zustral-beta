(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** Implements the region map type. *)
open Identifier
open Region

type region_map

val empty_region_map : region_map

val add_region : Error.place -> region_map -> identifier -> region -> region_map

val get_region : region_map -> identifier -> region option

(** How many regions of the map are named for an anonymous borrow of one
    variable: the first has the given name, and each later one that name and
    its number in parentheses. *)
val count_regions_named_for_borrows_of : region_map -> string -> int
