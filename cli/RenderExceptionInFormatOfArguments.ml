(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Zustral_core
open Error
open ErrorReportingModeOfArguments

let render_exception_in_format_of_arguments (args: string list) (exn: exn): string =
  let error: zustral_error = error_of_exception exn in
  match error_reporting_mode_of_arguments args with
  | ErrorReportPlain ->
     render_error_to_plain error
  | ErrorReportJson ->
     Yojson.Basic.pretty_to_string (render_error_to_json error)
