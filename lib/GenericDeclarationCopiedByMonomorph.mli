(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Id
open EnvTypes
open MonoTypeBindings

(** A generic record, union, function or instance method: what a monomorph is a
    copy of. *)
type generic_declaration =
  | GenericRecord of record_id
  | GenericUnion of union_id
  | GenericFunction of function_id
  | GenericInstanceMethod of ins_meth_id

(** A monomorph, seen as the copy of a generic declaration for a list of type
    arguments, whatever the kind of the declaration. *)
type copy_of_generic_declaration = {
    copy_id: mono_id;
    declaration: generic_declaration;
    type_arguments: mono_type_bindings;
  }

val copy_of_generic_declaration_made_by_monomorph : monomorph -> copy_of_generic_declaration
