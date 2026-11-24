(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** How the compiler writes an error to stderr. *)
type error_reporting_mode =
  | ErrorReportPlain
  (** Text for a person. *)
  | ErrorReportJson
  (** JSON for a tool. *)

(** The format the command line asks for: JSON if an argument after the name
    of the binary is [--error-format=json], wherever it is, and plain text
    otherwise. It is read from the arguments as they are, before they are
    parsed, so that an error in the arguments themselves is in this format too
    (issue #174). *)
val error_reporting_mode_of_arguments : string list -> error_reporting_mode
