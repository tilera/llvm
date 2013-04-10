##===- lib/Target/Tile/Makefile ----------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMTileCodeGen
TARGET = Tile

# Make sure that tblgen is run, first thing.
BUILT_SOURCES = TileGenRegisterInfo.inc TileGenInstrInfo.inc \
                TileGenAsmWriter.inc TileGenDAGISel.inc \
		TileGenCallingConv.inc TileGenSubtargetInfo.inc \
		TileGenMCCodeEmitter.inc TileGenAsmMatcher.inc \
		TileGenDFAPacketizer.inc
DIRS = InstPrinter AsmParser TargetInfo MCTargetDesc

include $(LEVEL)/Makefile.common

