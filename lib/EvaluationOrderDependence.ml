(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Stages.Tast

let rec depends_on_evaluation_order (expr: texpr): bool =
  let depends: texpr -> bool = depends_on_evaluation_order in
  match expr with
  | TNilConstant | TBoolConstant _ | TIntConstant _ | TFloatConstant _ | TStringConstant _
  | TConstVar _ | TFunVar _ | TTemporary _ | TSizeOf _ | TParamVar _ | TLocalVar _ ->
     false
  | TFuncall _ | TMethodCall _ | TVarMethodCall _ | TFptrCall _ | TEmbed _
  | TArithmeticNegation _ | TArrayIndex _ | TSpanIndex _ ->
     true
  | TCast (operand, _) | TImplicitCast (operand, _) | TNegation operand | TDeref (operand, _)
  | TSlotAccessor (operand, _, _) | TPointerSlotAccessor (operand, _, _) ->
     depends operand
  | TComparison (_, left, right) | TConjunction (left, right) | TDisjunction (left, right) ->
     depends left || depends right
  | TIfExpression (condition, if_true, if_false) ->
     depends condition || depends if_true || depends if_false
  | TRecordConstructor (_, values) | TUnionConstructor { args = values; _ } ->
     List.exists (fun (_, value) -> depends value) values
