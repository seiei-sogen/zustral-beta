(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* The wording of errors that no program makes the compiler raise, and the
   parts of the error printer and the command line that no program reaches. *)
open OUnit2
open Zustral_core
open Zustral_core.Identifier
open Zustral_core.Error
open Zustral_core.SourceContext
open TestUtil

let wording (error: error): string =
  ErrorText.error_text_to_plain (error_text error)

let raised_wording (f: unit -> 'a): string =
  try
    ignore (f ());
    assert_failure "No error was raised."
  with Zustral_error (ZustralError { error; _ }) ->
    error_title error ^ ": " ^ wording error

let test_generic_wording _ =
  let open GenericErrors in
  eq "Cannot add symbol to the import map twice." (wording (Generic SymbolImportedTwice));
  eq "Parameter not found." (wording (Generic ParameterNotFound));
  let type_parameter_without_argument = TypeParameter.make_typaram (make_ident "A", Type.FreeUniverse, make_qident (make_mod_name "Test", make_ident "C", make_ident "C"), []) in
  eq ("Parameter list and argument list don't have the same length:\n\nparameters:\n" ^ TypeParameter.show_type_parameter type_parameter_without_argument ^ "\narguments:\n")
    (wording (Generic (ParameterArgumentLengthMismatch { parameters = [type_parameter_without_argument]; arguments = [] })));
  eq "No binding for this parameter: T" (wording (Generic (NoBindingForParameter (make_ident "T"))));
  eq "Not allowed" (wording (Generic InstanceOverlapTypeNotAllowed))

let test_declaration_wording _ =
  let open DeclarationErrors in
  eq "Typeclass arguments cannot be regions." (wording (Declaration InstanceArgumentRegion))

let test_parse_wording _ =
  eq "Character not allowed in string literal: `\\x00`"
    (wording (Parse (ParseErrors.StringInvalidCharacter "\\x00")))

let test_popping_flag_of_other_kind _ =
  let open Zustral_cli.CliUtil in
  let arglist = parse_args ["bin"; "pos"; "--a=1"; "--b"] in
  eq "Command Line Arguments Error: Expected `a` to be a boolean flag, but it was given as a value flag."
    (raised_wording (fun () -> pop_bool_flag arglist "a"));
  eq "Command Line Arguments Error: Expected `b` to be a value flag, but it was given as a boolean flag."
    (raised_wording (fun () -> pop_value_flag arglist "b"))

let test_write_error_wording _ =
  eq "Failed to write to file `out.c`: \n\nIs a directory"
    (wording (Cli (CliErrors.WriteError { path = "out.c"; reason = "Is a directory" })))

let test_write_to_full_device _ =
  eq "Command Line Arguments Error: Failed to write to file `/dev/full`: \n\nNo space left on device"
    (raised_wording (fun () -> Zustral_cli.Os.write_string_to_file "/dev/full" "x"))

(* The code of a command that a signal killed is what a shell reports: 128
   and the system's number of the signal (issue #144). *)
let test_command_killed_by_signal _ =
  let (Zustral_cli.Os.CommandOutput { code; _ }) = Zustral_cli.Os.run_command "kill -9 $$" in
  eq 137 code

(* No program makes the compiler raise an exception other than its errors once
   its bugs are fixed, so this calls the conversion that Cli.main uses. *)
let test_unexpected_exception_is_an_internal_error _ =
  let title_and_wording (error: zustral_error): string =
    let (ZustralError { error; _ }) = error in
    error_title error ^ ": " ^ wording error
  in
  eq "Internal Error: Internal compiler error: Failure(\"boom\")\n\nThis is a bug in the compiler, please open an issue here: `https://github.com/seiei-sogen/zustral-beta/issues`"
    (title_and_wording (error_of_exception (Failure "boom")));
  let reported = make_error NoSpan (Generic GenericErrors.LeftoverArguments) in
  eq reported (error_of_exception (Zustral_error reported))

(* The exception that ends the compiler is reported in JSON when an argument
   is `--error-format=json` (issue #174): this is the text Cli.main writes. *)
let test_exception_is_reported_in_the_format_the_arguments_ask_for _ =
  let open Zustral_cli.RenderExceptionInFormatOfArguments in
  let open Yojson.Basic.Util in
  let reported_in_json (exn: exn): Yojson.Basic.t =
    Yojson.Basic.from_string (render_exception_in_format_of_arguments ["zustral"; "compile"; "A.zum"; "--error-format=json"] exn)
  in
  let second_text_content (json: Yojson.Basic.t): string =
    to_string (member "content" (List.nth (to_list (member "text" json)) 1))
  in
  (* An exception other than the compiler's errors is an internal error. *)
  let json = reported_in_json Not_found in
  eq "Internal Error" (to_string (member "kind" json));
  eq "Not_found" (second_text_content json);
  (* The characters that JSON escapes, and the others, come back as they were. *)
  let message = "quote \" backslash \\ non-ASCII \xc3\xa9 control \x01\n" in
  eq message (second_text_content (reported_in_json (Zustral_error (make_error NoSpan (Internal message)))));
  (* The first argument is the name of the binary, not an argument, and there
     may be no arguments at all: plain text. *)
  List.iter (fun (args: string list) ->
      assert_bool "plain text"
        (String.starts_with ~prefix:"Error:\n  Title: Internal Error\n" (render_exception_in_format_of_arguments args Not_found)))
    [["--error-format=json"]; []]

let module_of (error: zustral_error): string option =
  let (ZustralError { location; _ }) = error in
  Option.map mod_name_string (location_module_name location)

let test_module_name_is_added_once _ =
  let first = make_mod_name "First" and second = make_mod_name "Second" in
  let without_span = add_module_name (make_error NoSpan (Internal "x")) first in
  eq (Some "First") (module_of (add_module_name without_span second));
  let with_span = add_module_name (make_error (AtSpan (simplespan "x")) (Internal "x")) first in
  eq (Some "First") (module_of (add_module_name with_span second))

let source_ctx_of (error: zustral_error): source_ctx option =
  let (ZustralError { source_ctx; _ }) = error in
  source_ctx

let test_source_context_is_added_once _ =
  let first = SourceContext [(1, "first")] and second = SourceContext [(1, "second")] in
  let error = add_source_ctx (make_error NoSpan (Internal "x")) first in
  eq (Some first) (source_ctx_of (add_source_ctx error second))

let test_line_numbers_are_right_aligned _ =
  eq " 9 | a\n10 | b" (source_ctx_to_plain_text (SourceContext [(9, "a"); (10, "b")]))

let suite =
  "Unexecuted wording" >::: [
      "Generic errors" >:: test_generic_wording;
      "Declaration errors" >:: test_declaration_wording;
      "Parse errors" >:: test_parse_wording;
      "Popping a flag of the other kind" >:: test_popping_flag_of_other_kind;
      "Write error" >:: test_write_error_wording;
      "Write to a full device" >:: test_write_to_full_device;
      "Command killed by a signal" >:: test_command_killed_by_signal;
      "Unexpected exception is an internal error" >:: test_unexpected_exception_is_an_internal_error;
      "Exception is reported in the format the arguments ask for" >:: test_exception_is_reported_in_the_format_the_arguments_ask_for;
      "Module name is added once" >:: test_module_name_is_added_once;
      "Source context is added once" >:: test_source_context_is_added_once;
      "Line numbers are right aligned" >:: test_line_numbers_are_right_aligned
    ]

let _ = run_test_tt_main suite
