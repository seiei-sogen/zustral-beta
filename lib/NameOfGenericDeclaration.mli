(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Identifier
open Env
open GenericDeclarationCopiedByMonomorph

(** The name the declaration was given, without its module. *)
val name_of_generic_declaration : env -> generic_declaration -> identifier
