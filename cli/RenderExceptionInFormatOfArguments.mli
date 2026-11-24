(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The text the compiler writes to stderr for the exception that ends it:
    the error the exception carries, or an internal error that names any other
    exception, in the format that the arguments ask for
    ({!ErrorReportingModeOfArguments.error_reporting_mode_of_arguments}). *)
val render_exception_in_format_of_arguments : string list -> exn -> string
