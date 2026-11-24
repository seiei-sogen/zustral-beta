(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Env
open EnvTypes

(** The lineage of each monomorph that the instantiation of another registered:
    the monomorph that registered it, the one that registered that one, and so
    on, with how the type arguments of the copies of each generic declaration
    among them deepen. *)
type lineages

val no_lineages : lineages

(** The lineages, with those of the monomorphs that the instantiation of the
    first monomorph registered (the list). Raises the error of issue #176 when a
    generic declaration has used itself 8 times, each with type arguments that
    nest deeper than at every use before: its copies would never end. *)
val lineages_with_monomorphs_registered_by : env -> lineages -> monomorph -> monomorph list -> lineages
