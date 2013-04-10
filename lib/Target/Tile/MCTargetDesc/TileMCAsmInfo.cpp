//===-- TileMCAsmInfo.cpp - Tile Asm Properties ---------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the TileMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "TileMCAsmInfo.h"
#include "llvm/ADT/Triple.h"

using namespace llvm;

void TileMCAsmInfo::anchor() {}

TileMCAsmInfo::TileMCAsmInfo(const Target &T, StringRef TT) {
  Triple TheTriple(TT);
  PointerSize = 8;
  AlignmentIsInBytes = true;
  Data16bitsDirective = "\t.2byte\t";
  Data32bitsDirective = "\t.4byte\t";
  PrivateGlobalPrefix = ".L";
  CommentString = "#";
  ZeroDirective = "\t.space\t";
  WeakRefDirective = "\t.weak\t";

  // tilegx assembler do not support .bss, we
  // should always use .section .bss
  UsesELFSectionDirectiveForBSS = true;

  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::DwarfCFI;
  HasLEB128 = true;
  DwarfRegNumForCFI = true;
}
