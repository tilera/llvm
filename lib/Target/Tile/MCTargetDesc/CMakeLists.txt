add_llvm_library(LLVMTileDesc
  TileAsmBackend.cpp
  TileMCAsmInfo.cpp
  TileMCCodeEmitter.cpp
  TileMCTargetDesc.cpp
  TileELFObjectWriter.cpp
  )

add_dependencies(LLVMTileDesc TileCommonTableGen)
