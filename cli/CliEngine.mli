(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(** Executes parsed CLI commands. *)
open CliParser

(** Run a command. Raises [Zustral_error] for every error: in the command
    itself, in reading the source files, and in the compilation. *)
val exec : cmd -> unit
