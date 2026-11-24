(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

type error_reporting_mode =
  | ErrorReportPlain
  | ErrorReportJson

let error_reporting_mode_of_arguments (args: string list): error_reporting_mode =
  (* The first argument is the name of the binary, as in CliUtil.parse_args. *)
  match args with
  | [] ->
     ErrorReportPlain
  | _ :: arguments ->
     if List.mem "--error-format=json" arguments then ErrorReportJson else ErrorReportPlain
