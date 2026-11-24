(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Util
open Error

type escaped_string = EscapedString of string

let rec escape_string (place: place) s =
  EscapedString (string_implode (escape_list place (string_explode s)))

and escape_list place lst =
  match lst with
  | ('\\' :: 'n' :: rest) -> '\n' :: (escape_list place rest)
  | ('\\' :: 'r' :: rest) -> '\r' :: (escape_list place rest)
  | ('\\' :: 't' :: rest) -> '\t' :: (escape_list place rest)
  | ('\\' :: '\'' :: rest) -> '\'' :: (escape_list place rest)
  | ('\\' :: '"' :: rest) -> '"' :: (escape_list place rest)
  | ('\\' :: '\\' :: rest) -> '\\' :: (escape_list place rest)
  | ('\\' :: ' ' :: rest) -> consume_whitespace place (' ' :: rest)
  | ('\\' :: '\n' :: rest) -> consume_whitespace place (' ' :: rest)
  | ('\\' :: '\r' :: rest) -> consume_whitespace place (' ' :: rest)
  | ('\\' :: '\t' :: rest) -> consume_whitespace place (' ' :: rest)
  | ('\\' :: after_backslash) ->
     generic_error place (UnknownEscapeSequence (first_utf8_character_of_bytes after_backslash))
  | (head :: rest) -> head :: (escape_list place rest)
  | nil -> nil

(* The first character of the bytes: its first byte and the UTF-8 continuation
   bytes after it. Empty when the backslash ends the string. *)
and first_utf8_character_of_bytes (bytes: char list): string =
  let is_utf8_continuation_byte (byte: char): bool = Char.code byte land 0xC0 = 0x80 in
  let rec leading_continuation_bytes (rest: char list): char list =
    match rest with
    | byte :: rest when is_utf8_continuation_byte byte -> byte :: leading_continuation_bytes rest
    | _ -> []
  in
  match bytes with
  | first_byte :: rest -> string_implode (first_byte :: leading_continuation_bytes rest)
  | [] -> ""

and consume_whitespace place lst =
  match lst with
  | (' '  :: rest) -> consume_whitespace place rest
  | ('\n' :: rest) -> consume_whitespace place rest
  | ('\r' :: rest) -> consume_whitespace place rest
  | ('\t' :: rest) -> consume_whitespace place rest
  | ('\\' :: rest) -> escape_list place rest
  | _ -> generic_error place BadWhitespaceEscape

let escaped_to_string (EscapedString s) =
  s

let rec unescape_string (EscapedString s) =
  String.concat "" (List.map unescape_char (string_explode s))

and unescape_char = function
  | '\n' -> "\\n"
  | '\r' -> "\\r"
  | '\t' -> "\\t"
  | '\'' -> "\\\'"
  | '\\' -> "\\\\"
  | '"' -> "\\\""
  | c -> String.make 1 c
