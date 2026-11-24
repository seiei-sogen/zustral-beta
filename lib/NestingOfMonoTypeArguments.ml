(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Env
open GenericDeclarationCopiedByMonomorph
open MonoType
open MonoTypeBindings

(* How deeply the type nests types: 0 for `Int32`, 1 for `Option[Int32]`, 2 for
   `Option[Option[Int32]]`. The region of a reference or a span does not count. *)
let rec nesting_of_mono_type (env: env) (ty: mono_ty): int =
  match ty with
  | MonoUnit | MonoBoolean | MonoInteger _ | MonoSingleFloat | MonoDoubleFloat | MonoRegionTy _ ->
     0
  | MonoNamedType id ->
     let { type_arguments; _ } = copy_of_generic_declaration_made_by_monomorph (get_monomorph env id) in
     1 + nesting_of_mono_type_arguments env type_arguments
  | MonoReadRef (ty, _) | MonoWriteRef (ty, _) | MonoSpan (ty, _) | MonoSpanMut (ty, _) | MonoAddress ty | MonoPointer ty ->
     1 + nesting_of_mono_type env ty
  | MonoFnPtr (parameters, return_type) ->
     1 + deepest_nesting_of_mono_types env (return_type :: parameters)

and deepest_nesting_of_mono_types (env: env) (types: mono_ty list): int =
  List.fold_left (fun deepest ty -> max deepest (nesting_of_mono_type env ty)) 0 types

(* The nesting of the type argument that nests deepest: 0 without type arguments. *)
and nesting_of_mono_type_arguments (env: env) (type_arguments: mono_type_bindings): int =
  deepest_nesting_of_mono_types env (List.map snd (mono_bindings_as_list type_arguments))
