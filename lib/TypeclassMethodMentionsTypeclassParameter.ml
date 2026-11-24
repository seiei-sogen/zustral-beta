(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Identifier
open Type
open TypeSystem
open TypeParameter
open TypeVarSet
open Error
open DeclarationErrors

(* A call of a method finds its instance by the type in the place of the
   typeclass's parameter, so the method's parameters or its return type mention
   that parameter. Checked where the typeclass is declared (#175); before, every
   call of such a method failed. *)
let check_typeclass_method_mentions_typeclass_parameter
      (place: place)
      (typeclass: identifier)
      (typeclass_param: type_parameter)
      (method_name: identifier)
      (params: value_parameter list)
      (rt: ty): unit =
  let type_mentions_typeclass_parameter (ty: ty): bool =
    TypeVarSet.mem (typaram_to_tyvar typeclass_param) (type_variables ty)
  in
  if List.exists (fun (ValueParameter (_, ty)) -> type_mentions_typeclass_parameter ty) params || type_mentions_typeclass_parameter rt then
    ()
  else
    declaration_error place (MethodWithoutTypeclassParameter {
        typeclass;
        method_name;
        typaram = typaram_name typeclass_param;
      })
