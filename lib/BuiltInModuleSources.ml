(*
   Part of the Austral project, under the Apache License v2.0 with LLVM Exceptions.
   Modified in the Zustral project, a fork of Austral.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
open Pipeline
open BuiltInModules

let built_in_module_sources: module_source list = [
    TwoFileModuleSource {
        int_filename = "lib/builtin/Pervasive.zui";
        int_code = pervasive_interface_source;
        body_filename = "lib/builtin/Pervasive.zum";
        body_code = pervasive_body_source
      };
    TwoFileModuleSource {
        int_filename = "lib/builtin/Memory.zui";
        int_code = memory_interface_source;
        body_filename = "lib/builtin/Memory.zum";
        body_code = memory_body_source
      }
  ]
