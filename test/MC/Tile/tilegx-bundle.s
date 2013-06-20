# DISABLE: llvm-mc -triple=tilegx -show-encoding < %s | FileCheck %s
# RUN: false
# XFAIL: *

# No support for bundled format yet.

  .globl _func
_func:
# CHECK: _func

{
add r7, r27, r50 
add lr, tp, r27 
}
