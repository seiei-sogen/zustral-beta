(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Identifier
open Env
open EnvTypes
open GenericDeclarationCopiedByMonomorph
open Error

let name_of_generic_declaration (env: env) (declaration: generic_declaration): identifier =
  match declaration with
  | GenericRecord id ->
     let { name; _ }: record_decl = get_record env id in
     name
  | GenericUnion id ->
     let { name; _ }: union_decl = get_union NoSpan env id in
     name
  | GenericFunction id ->
     let { name; _ }: function_decl = get_function env id in
     name
  | GenericInstanceMethod id ->
     let (InsMethRec { name; _ }) = get_instance_method env id in
     name
