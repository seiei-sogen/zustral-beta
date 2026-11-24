(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Id
open Env
open EnvTypes
open GenericDeclarationCopiedByMonomorph
open NameOfGenericDeclaration
open NestingOfMonoTypeArguments
open Error

(* For a generic declaration: the nesting of the type arguments of its copy that
   nests deepest, and how many copies nested deeper than every copy before them. *)
type deepening = { deepest_nesting: int; times_deepened: int }

module GenericDeclarationMap =
  Map.Make (struct
      type t = generic_declaration
      (* An ID is plain data. *)
      let compare: t -> t -> int = Stdlib.compare
    end)

(* The lineage of a monomorph: the monomorph whose instantiation registered it,
   the one that registered that one, and so on. It keeps, for each generic
   declaration with a copy among them (the monomorph itself is one), the
   deepening over its copies. *)
type lineage = deepening GenericDeclarationMap.t

module MonomorphIdMap =
  Map.Make (struct
      type t = mono_id
      let compare (a: t) (b: t): int = Int.compare (mono_id_number a) (mono_id_number b)
    end)

(* The lineage of each monomorph that the instantiation of another registered.
   A monomorph without one was registered by a declaration that is not generic. *)
type lineages = lineage MonomorphIdMap.t

let no_lineages: lineages = MonomorphIdMap.empty

(* A generic declaration that uses itself this many times, each with type
   arguments that nest deeper than at every use before, is taken to do so
   without end. A program that ends does it once per instance written for a
   deeper type, which the typeclasses of no program do 8 times. The check must
   not wait long: a declaration that uses itself twice doubles its copies at
   each step. A use that nests as deep or less deep does not count, and does
   not start the count again: `f[A, B]` that uses `f[B, Option[A]]` nests
   deeper only at every other use. *)
let maximum_times_a_generic_declaration_deepens: int = 8

(* The lineages, with those of the monomorphs that the instantiation of
   `registrant` registered. A generic declaration that uses itself with a type
   argument that nests deeper at each use (`Option[T]` for its `T`) registers a
   copy at each instantiation, without end: that is the error here (issue #176). *)
let lineages_with_monomorphs_registered_by (env: env) (lineages: lineages) (registrant: monomorph) (registered: monomorph list): lineages =
  let lineage_of_registrant: lineage =
    let { copy_id; declaration; type_arguments } = copy_of_generic_declaration_made_by_monomorph registrant in
    match MonomorphIdMap.find_opt copy_id lineages with
    | Some lineage ->
       lineage
    | None ->
       GenericDeclarationMap.singleton declaration { deepest_nesting = nesting_of_mono_type_arguments env type_arguments; times_deepened = 0 }
  in
  let with_lineage_of (lineages: lineages) (mono: monomorph): lineages =
    let { copy_id; declaration; type_arguments } = copy_of_generic_declaration_made_by_monomorph mono in
    let nesting: int = nesting_of_mono_type_arguments env type_arguments in
    let deepening: deepening =
      match GenericDeclarationMap.find_opt declaration lineage_of_registrant with
      | Some before when nesting > before.deepest_nesting ->
         { deepest_nesting = nesting; times_deepened = before.times_deepened + 1 }
      | Some before ->
         before
      | None ->
         { deepest_nesting = nesting; times_deepened = 0 }
    in
    if deepening.times_deepened >= maximum_times_a_generic_declaration_deepens then
      generic_error NoSpan (GenericDeclarationUsesItselfWithDeeperTypeArguments {
        declaration = name_of_generic_declaration env declaration;
        times_deepened = deepening.times_deepened
      })
    else
      MonomorphIdMap.add copy_id (GenericDeclarationMap.add declaration deepening lineage_of_registrant) lineages
  in
  List.fold_left with_lineage_of lineages registered
