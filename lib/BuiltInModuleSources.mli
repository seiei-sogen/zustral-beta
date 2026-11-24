(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The built-in modules, in the order the compiler compiles them before the
    given ones: [Zustral.Memory] uses declarations of [Zustral.Pervasive].

    Each file name is the path of the source in the repository of the
    compiler, so an error in a built-in module names its file, and the command
    line shows its lines (issue #172). *)
val built_in_module_sources : Pipeline.module_source list
