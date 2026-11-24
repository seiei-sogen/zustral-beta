(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Zustral_core
open Unix
open Error

(* The message of [Sys_error] starts with the path when the file cannot be
   opened, and not when it cannot be read or written. The error names the
   path itself. *)
let reason_without_path (path: string) (reason: string): string =
  let prefix = path ^ ": " in
  if String.starts_with ~prefix reason then
    String.sub reason (String.length prefix) (String.length reason - String.length prefix)
  else
    reason

(* Reads in a loop, not by recursion per line: a long file must not use up the
   stack (#93). In_channel.input_all would do, but it needs OCaml 4.14, and
   the build on macOS uses 4.13. *)
let read_stream_to_string (stream: in_channel): string =
  let contents = Buffer.create 65536 in
  let chunk = Bytes.create 65536 in
  let rec read_chunks () =
    let length = input stream chunk 0 (Bytes.length chunk) in
    if length > 0 then begin
      Buffer.add_subbytes contents chunk 0 length;
      read_chunks ()
    end
  in
  read_chunks ();
  Buffer.contents contents

(* The text without the whitespace at its end. The whitespace at the start
   stays: removing the blank lines at the start of a source file would move
   every position after them (issue #172). Without the blank lines at its end,
   an error at the end of the file points at the last line that has text. *)
let without_whitespace_at_the_end (text: string): string =
  let is_whitespace (character: char): bool = String.contains " \012\n\r\t" character in
  let rec length_without_whitespace_at_the_end (length: int): int =
    if length > 0 && is_whitespace text.[length - 1] then length_without_whitespace_at_the_end (length - 1) else length
  in
  String.sub text 0 (length_without_whitespace_at_the_end (String.length text))

let read_file_to_string (path: string): string =
  try
    let stream = open_in path in
    Fun.protect ~finally:(fun () -> close_in_noerr stream) (fun () -> without_whitespace_at_the_end (read_stream_to_string stream))
  with Sys_error reason ->
    cli_error NoSpan (ReadError { path; reason = reason_without_path path reason })

let write_string_to_file (path: string) (contents: string): unit =
  try
    let stream = open_out path in
    Fun.protect ~finally:(fun () -> close_out_noerr stream) (fun () ->
        output_string stream contents;
        (* Closing flushes, and close_out_noerr would close without reporting
           a failure (a full disk). *)
        close_out stream)
  with Sys_error reason ->
    cli_error NoSpan (WriteError { path; reason = reason_without_path path reason })

type command_output =
  CommandOutput of { command: string; code: int; stdout: string; stderr: string }

let run_command (command: string): command_output =
  let path: string =
    match Sys.getenv_opt "PATH" with
    | Some path -> path
    | None -> c_compiler_error NoSpan PathVariableNotSet
  in
  (* The command writes its stderr to a file, and only its stdout to a pipe.
     With a pipe for each, the command waits when it fills the one that is not
     being read, and this waits for the end of the other: neither finishes
     (issue #173). *)
  let stderr_path: string = Filename.temp_file "zustral_" ".stderr" in
  (* The file may be gone already (a cleaner of the temporary directory). *)
  Fun.protect ~finally:(fun () -> if Sys.file_exists stderr_path then Sys.remove stderr_path) (fun () ->
      (* `exec` moves the stderr of the shell itself, on a line before the
         command: what the shell says of a command it cannot parse is in the
         file too. *)
      let command_with_stderr_in_file: string = "exec 2> " ^ Filename.quote stderr_path ^ "\n" ^ command in
      let (stdout_chan, stdin_chan, stderr_chan) = open_process_full command_with_stderr_in_file [|"PATH=" ^ path|] in
      let stdout = String.trim (read_stream_to_string stdout_chan) in
      let proc_stat = close_process_full (stdout_chan, stdin_chan, stderr_chan) in
      CommandOutput {
          command = command;
          code = ProcessStatus.exit_code proc_stat;
          stdout = stdout;
          stderr = String.trim (read_file_to_string stderr_path)
        })

let compile_c_code (source_path: string) (output_path: string): command_output =
  let cmd = "cc " ^ source_path ^ " -fwrapv -lm -o " ^ output_path in
  let o = run_command cmd in
  let (CommandOutput { command; code; stdout; stderr }) = o in
  if code <> 0 then
    c_compiler_error NoSpan (CCompilerFailed { command; exit_code = code; stdout; stderr })
  else
    o
