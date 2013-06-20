; RUN: llc -march=tilegx -O3 -relocation-model=pic -filetype=obj < %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:32-i16:16:32-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-n32"
target triple = "tilegx-unknown-linux-gnu"

@global_a = global i32 16, align 4

define i32 @cal(i32 %a) #0 {
entry:
  %0 = load i32* @global_a, align 4, !tbaa !0
  %add = add nsw i32 %0, %a
  ret i32 %add
}

attributes #0 = { nounwind readonly "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-frame-pointer-elim-non-leaf"="true" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="true" }

!0 = metadata !{metadata !"int", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}
