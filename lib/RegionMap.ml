(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

open IdentifierMap
open Error
open Region

type region_map = region IdentifierMap.t

let empty_region_map = IdentifierMap.empty

let get_region m n =
  IdentifierMap.find_opt n m

let add_region (place: place) m n r =
  match get_region m n with
  | Some _ ->
     generic_error place RegionAlreadyExists
  | None ->
     IdentifierMap.add n r m

let count_regions_named_for_borrows_of (m: region_map) (name_of_first: string): int =
  let is_named_for_the_borrows (_: Identifier.identifier) (region: region): bool =
    let name: string = Identifier.ident_string (region_name region) in
    String.equal name name_of_first || String.starts_with ~prefix:(name_of_first ^ " (") name
  in
  IdentifierMap.cardinal (IdentifierMap.filter is_named_for_the_borrows m)
