(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Env
open MonoTypeBindings

(** How deeply the type argument that nests deepest nests types: 0 without type
    arguments or for `Int32`, 1 for `Option[Int32]`, 2 for
    `Option[Option[Int32]]`. The region of a reference or a span does not count. *)
val nesting_of_mono_type_arguments : env -> mono_type_bindings -> int
