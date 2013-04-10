; RUN: %lli_mcjit %s > /dev/null

%struct.large = type {
i64, i64, i64, i64,
i64, i64, i64, i64,
i64, i64, i64, i64
}

define i64 @bar(%struct.large* byval %a) nounwind {
entry:
  %a0 = getelementptr inbounds %struct.large* %a, i32 0, i32 0
  %0 = load i64* %a0, align 8
  %a1 = getelementptr inbounds %struct.large* %a, i32 0, i32 11
  %1 = load i64* %a1, align 8
  %add1 = add nsw i64 %0, %1
  ret i64 %add1
}

define i64 @foo() nounwind {
entry:
  %t0 = alloca %struct.large, align 8
  %a0 = getelementptr inbounds %struct.large* %t0, i32 0, i32 0
  store i64 11, i64* %a0, align 8
  %a1 = getelementptr inbounds %struct.large* %t0, i32 0, i32 11
  store i64 22, i64* %a1, align 8
  %call = call i64 @bar(%struct.large* byval %t0)
  ret i64 %call
}

define i32 @main() nounwind {
entry:
  %retval = alloca i32, align 4
  store i32 0, i32* %retval
  %call = call i64 bitcast (i64 ()* @foo to i64 ()*)()
  %cmp = icmp ne i64 %call, 33
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  store i32 1, i32* %retval
  unreachable

if.else:                                          ; preds = %entry
  store i32 0, i32* %retval
  br label %return

return:                                           ; preds = %if.else, %if.then
  %0 = load i32* %retval
  ret i32 %0

}
