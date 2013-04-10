set(LLVM_TARGET_DEFINITIONS Tile.td)

tablegen(LLVM TileGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM TileGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM TileGenMCCodeEmitter.inc -gen-emitter -mc-emitter)
tablegen(LLVM TileGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM TileGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM TileGenCallingConv.inc -gen-callingconv)
tablegen(LLVM TileGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM TileGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM TileGenDFAPacketizer.inc -gen-dfa-packetizer)
add_public_tablegen_target(TileCommonTableGen)

add_llvm_target(TileCodeGen
  TileAnalyzeImmediate.cpp
  TileAsmPrinter.cpp
  TileDelaySlotFiller.cpp
  TileEmitGPRestore.cpp
  TileExpandPseudo.cpp
  TileInstrInfo.cpp
  TileISelDAGToDAG.cpp
  TileISelLowering.cpp
  TileFrameLowering.cpp
  TileMCInstLower.cpp
  TileMachineFunction.cpp
  TileRegisterInfo.cpp
  TileSubtarget.cpp
  TileTargetMachine.cpp
  TileSelectionDAGInfo.cpp
  TileVLIWPacketizer.cpp
  )

add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(AsmParser)
