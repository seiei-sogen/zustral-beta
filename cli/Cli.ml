(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open CliUtil
open CliParser
open CliEngine
open RenderExceptionInFormatOfArguments

let rec main (args: string list): unit =
  try
    main' args;
    exit 0
  with exn ->
    (* Every error ends here, also one in the arguments themselves: the format
       is read from the arguments as they are (issue #174). *)
    prerr_string (render_exception_in_format_of_arguments args exn);
    (* Closing stderr writes the text, and ignores a stderr that cannot be
       written (closed, a full device). Left open, flushing it when the process
       ends raises Sys_error then, and the status is 2 instead of the one below.
       shortcut: a text longer than the buffer of stderr fails in the write
       above and still ends with status 2, as before issue #174; catch that
       Sys_error if the status matters. *)
    close_out_noerr stderr;
    exit (-1)

and main' (args: string list): unit =
  let arglist: arglist = parse_args args in
  let cmd: cmd = parse arglist in
  exec cmd
