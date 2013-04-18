//===-- TileRegisterInfo.td - Tile Register defs -----------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the TILE register file.
//===----------------------------------------------------------------------===//
let Namespace = "Tile" in {
  def sub_32     : SubRegIndex;
}

// We have banks of 32 registers each.
class TileReg<bits<16> Enc, string n> : Register<n> {
  let HWEncoding = Enc;
  let Namespace = "Tile";
}

class TileRegWithSubRegs<bits<16> Enc, string n, list<Register> subregs>
  : RegisterWithSubRegs<n, subregs> {
  let HWEncoding = Enc;
  let Namespace = "Tile";
}

// Tile CPU Registers.
class TileGPRReg<bits<16> Enc, string n> : TileReg<Enc, n>;

// Tile 64-bit CPU Registers.
class Tile64GPRReg<bits<16> Enc, string n, list<Register> subregs>
  : TileRegWithSubRegs<Enc, n, subregs> {
  let SubRegIndices = [sub_32];
}

//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

let Namespace = "Tile" in {
  // General Purpose 32-bit Registers.
  // For Tile, all regs are 64bit, we treate them as 32bit when
  // operated by 32bit instructions.
  def R0_32    : TileGPRReg< 0,  "r0">, DwarfRegNum<[0]>;
  def R1_32    : TileGPRReg< 1,  "r1">, DwarfRegNum<[1]>;
  def R2_32    : TileGPRReg< 2,  "r2">, DwarfRegNum<[2]>;
  def R3_32    : TileGPRReg< 3,  "r3">, DwarfRegNum<[3]>;
  def R4_32    : TileGPRReg< 4,  "r4">, DwarfRegNum<[4]>;
  def R5_32    : TileGPRReg< 5,  "r5">, DwarfRegNum<[5]>;
  def R6_32    : TileGPRReg< 6,  "r6">, DwarfRegNum<[6]>;
  def R7_32    : TileGPRReg< 7,  "r7">, DwarfRegNum<[7]>;
  def R8_32    : TileGPRReg< 8,  "r8">, DwarfRegNum<[8]>;
  def R9_32    : TileGPRReg< 9,  "r9">, DwarfRegNum<[9]>;
  def R10_32   : TileGPRReg< 10, "r10">, DwarfRegNum<[10]>;
  def R11_32   : TileGPRReg< 11, "r11">, DwarfRegNum<[11]>;
  def R12_32   : TileGPRReg< 12, "r12">, DwarfRegNum<[12]>;
  def R13_32   : TileGPRReg< 13, "r13">, DwarfRegNum<[13]>;
  def R14_32   : TileGPRReg< 14, "r14">, DwarfRegNum<[14]>;
  def R15_32   : TileGPRReg< 15, "r15">, DwarfRegNum<[15]>;
  def R16_32   : TileGPRReg< 16, "r16">, DwarfRegNum<[16]>;
  def R17_32   : TileGPRReg< 17, "r17">, DwarfRegNum<[17]>;
  def R18_32   : TileGPRReg< 18, "r18">, DwarfRegNum<[18]>;
  def R19_32   : TileGPRReg< 19, "r19">, DwarfRegNum<[19]>;
  def R20_32   : TileGPRReg< 20, "r20">, DwarfRegNum<[20]>;
  def R21_32   : TileGPRReg< 21, "r21">, DwarfRegNum<[21]>;
  def R22_32   : TileGPRReg< 22, "r22">, DwarfRegNum<[22]>;
  def R23_32   : TileGPRReg< 23, "r23">, DwarfRegNum<[23]>;
  def R24_32   : TileGPRReg< 24, "r24">, DwarfRegNum<[24]>;
  def R25_32   : TileGPRReg< 25, "r25">, DwarfRegNum<[25]>;
  def R26_32   : TileGPRReg< 26, "r26">, DwarfRegNum<[26]>;
  def R27_32   : TileGPRReg< 27, "r27">, DwarfRegNum<[27]>;
  def R28_32   : TileGPRReg< 28, "r28">, DwarfRegNum<[28]>;
  def R29_32   : TileGPRReg< 29, "r29">, DwarfRegNum<[29]>;
  def R30_32   : TileGPRReg< 30, "r30">, DwarfRegNum<[30]>;
  def R31_32   : TileGPRReg< 31, "r31">, DwarfRegNum<[31]>;
  def R32_32   : TileGPRReg< 32, "r32">, DwarfRegNum<[32]>;
  def R33_32   : TileGPRReg< 33, "r33">, DwarfRegNum<[33]>;
  def R34_32   : TileGPRReg< 34, "r34">, DwarfRegNum<[34]>;
  def R35_32   : TileGPRReg< 35, "r35">, DwarfRegNum<[35]>;
  def R36_32   : TileGPRReg< 36, "r36">, DwarfRegNum<[36]>;
  def R37_32   : TileGPRReg< 37, "r37">, DwarfRegNum<[37]>;
  def R38_32   : TileGPRReg< 38, "r38">, DwarfRegNum<[38]>;
  def R39_32   : TileGPRReg< 39, "r39">, DwarfRegNum<[39]>;
  def R40_32   : TileGPRReg< 40, "r40">, DwarfRegNum<[40]>;
  def R41_32   : TileGPRReg< 41, "r41">, DwarfRegNum<[41]>;
  def R42_32   : TileGPRReg< 42, "r42">, DwarfRegNum<[42]>;
  def R43_32   : TileGPRReg< 43, "r43">, DwarfRegNum<[43]>;
  def R44_32   : TileGPRReg< 44, "r44">, DwarfRegNum<[44]>;
  def R45_32   : TileGPRReg< 45, "r45">, DwarfRegNum<[45]>;
  def R46_32   : TileGPRReg< 46, "r46">, DwarfRegNum<[46]>;
  def R47_32   : TileGPRReg< 47, "r47">, DwarfRegNum<[47]>;
  def R48_32   : TileGPRReg< 48, "r48">, DwarfRegNum<[48]>;
  def R49_32   : TileGPRReg< 49, "r49">, DwarfRegNum<[49]>;
  def R50_32   : TileGPRReg< 50, "r50">, DwarfRegNum<[50]>;
  def R51_32   : TileGPRReg< 51, "r51">, DwarfRegNum<[51]>;
  def FP_32    : TileGPRReg< 52, "r52">, DwarfRegNum<[52]>;
  def TP_32    : TileGPRReg< 53, "tp">,  DwarfRegNum<[53]>;
  def SP_32    : TileGPRReg< 54, "sp">,  DwarfRegNum<[54]>;
  def LR_32    : TileGPRReg< 55, "lr">,  DwarfRegNum<[55]>;
  def ZERO_32  : TileGPRReg< 63, "zero">,DwarfRegNum<[63]>;

  // General 64-bit Purpose Registers.
  def R0   : Tile64GPRReg< 0,  "r0",   [R0_32]>,    DwarfRegNum<[0]>;
  def R1   : Tile64GPRReg< 1,  "r1",   [R1_32]>,    DwarfRegNum<[1]>;
  def R2   : Tile64GPRReg< 2,  "r2",   [R2_32]>,    DwarfRegNum<[2]>;
  def R3   : Tile64GPRReg< 3,  "r3",   [R3_32]>,    DwarfRegNum<[3]>;
  def R4   : Tile64GPRReg< 4,  "r4",   [R4_32]>,    DwarfRegNum<[4]>;
  def R5   : Tile64GPRReg< 5,  "r5",   [R5_32]>,    DwarfRegNum<[5]>;
  def R6   : Tile64GPRReg< 6,  "r6",   [R6_32]>,    DwarfRegNum<[6]>;
  def R7   : Tile64GPRReg< 7,  "r7",   [R7_32]>,    DwarfRegNum<[7]>;
  def R8   : Tile64GPRReg< 8,  "r8",   [R8_32]>,    DwarfRegNum<[8]>;
  def R9   : Tile64GPRReg< 9,  "r9",   [R9_32]>,    DwarfRegNum<[9]>;
  def R10  : Tile64GPRReg< 10, "r10",  [R10_32]>,  DwarfRegNum<[10]>;
  def R11  : Tile64GPRReg< 11, "r11",  [R11_32]>,  DwarfRegNum<[11]>;
  def R12  : Tile64GPRReg< 12, "r12",  [R12_32]>,  DwarfRegNum<[12]>;
  def R13  : Tile64GPRReg< 13, "r13",  [R13_32]>,  DwarfRegNum<[13]>;
  def R14  : Tile64GPRReg< 14, "r14",  [R14_32]>,  DwarfRegNum<[14]>;
  def R15  : Tile64GPRReg< 15, "r15",  [R15_32]>,  DwarfRegNum<[15]>;
  def R16  : Tile64GPRReg< 16, "r16",  [R16_32]>,  DwarfRegNum<[16]>;
  def R17  : Tile64GPRReg< 17, "r17",  [R17_32]>,  DwarfRegNum<[17]>;
  def R18  : Tile64GPRReg< 18, "r18",  [R18_32]>,  DwarfRegNum<[18]>;
  def R19  : Tile64GPRReg< 19, "r19",  [R19_32]>,  DwarfRegNum<[19]>;
  def R20  : Tile64GPRReg< 20, "r20",  [R20_32]>,  DwarfRegNum<[20]>;
  def R21  : Tile64GPRReg< 21, "r21",  [R21_32]>,  DwarfRegNum<[21]>;
  def R22  : Tile64GPRReg< 22, "r22",  [R22_32]>,  DwarfRegNum<[22]>;
  def R23  : Tile64GPRReg< 23, "r23",  [R23_32]>,  DwarfRegNum<[23]>;
  def R24  : Tile64GPRReg< 24, "r24",  [R24_32]>,  DwarfRegNum<[24]>;
  def R25  : Tile64GPRReg< 25, "r25",  [R25_32]>,  DwarfRegNum<[25]>;
  def R26  : Tile64GPRReg< 26, "r26",  [R26_32]>,  DwarfRegNum<[26]>;
  def R27  : Tile64GPRReg< 27, "r27",  [R27_32]>,  DwarfRegNum<[27]>;
  def R28  : Tile64GPRReg< 28, "r28",  [R28_32]>,  DwarfRegNum<[28]>;
  def R29  : Tile64GPRReg< 29, "r29",  [R29_32]>,  DwarfRegNum<[29]>;
  def R30  : Tile64GPRReg< 30, "r30",  [R30_32]>,  DwarfRegNum<[30]>;
  def R31  : Tile64GPRReg< 31, "r31",  [R31_32]>,  DwarfRegNum<[31]>;
  def R32  : Tile64GPRReg< 32, "r32",  [R32_32]>, DwarfRegNum<[32]>;
  def R33  : Tile64GPRReg< 33, "r33",  [R33_32]>, DwarfRegNum<[33]>;
  def R34  : Tile64GPRReg< 34, "r34",  [R34_32]>, DwarfRegNum<[34]>;
  def R35  : Tile64GPRReg< 35, "r35",  [R35_32]>, DwarfRegNum<[35]>;
  def R36  : Tile64GPRReg< 36, "r36",  [R36_32]>, DwarfRegNum<[36]>;
  def R37  : Tile64GPRReg< 37, "r37",  [R37_32]>, DwarfRegNum<[37]>;
  def R38  : Tile64GPRReg< 38, "r38",  [R38_32]>, DwarfRegNum<[38]>;
  def R39  : Tile64GPRReg< 39, "r39",  [R39_32]>, DwarfRegNum<[39]>;
  def R40  : Tile64GPRReg< 40, "r40",  [R40_32]>, DwarfRegNum<[40]>;
  def R41  : Tile64GPRReg< 41, "r41",  [R41_32]>, DwarfRegNum<[41]>;
  def R42  : Tile64GPRReg< 42, "r42",  [R42_32]>, DwarfRegNum<[42]>;
  def R43  : Tile64GPRReg< 43, "r43",  [R43_32]>, DwarfRegNum<[43]>;
  def R44  : Tile64GPRReg< 44, "r44",  [R44_32]>, DwarfRegNum<[44]>;
  def R45  : Tile64GPRReg< 45, "r45",  [R45_32]>, DwarfRegNum<[45]>;
  def R46  : Tile64GPRReg< 46, "r46",  [R46_32]>, DwarfRegNum<[46]>;
  def R47  : Tile64GPRReg< 47, "r47",  [R47_32]>, DwarfRegNum<[47]>;
  def R48  : Tile64GPRReg< 48, "r48",  [R48_32]>, DwarfRegNum<[48]>;
  def R49  : Tile64GPRReg< 49, "r49",  [R49_32]>, DwarfRegNum<[49]>;
  def R50  : Tile64GPRReg< 50, "r50",  [R50_32]>, DwarfRegNum<[50]>;
  def R51  : Tile64GPRReg< 51, "r51",  [R51_32]>, DwarfRegNum<[51]>;
  def FP   : Tile64GPRReg< 52, "r52",  [FP_32]>,  DwarfRegNum<[52]>;
  def TP   : Tile64GPRReg< 53, "tp",   [TP_32]>,  DwarfRegNum<[53]>;
  def SP   : Tile64GPRReg< 54, "sp",   [SP_32]>,  DwarfRegNum<[54]>;
  def LR   : Tile64GPRReg< 55, "lr",   [LR_32]>,  DwarfRegNum<[55]>;
  def ZERO : Tile64GPRReg< 63, "zero", [ZERO_32]>,DwarfRegNum<[63]>;
}

//===----------------------------------------------------------------------===//
// Register Classes.
//===----------------------------------------------------------------------===//

def CPU32Regs : RegisterClass<"Tile", [i32, f32], 32, (add
  // Return Values and Arguments, caller saved.
  (sequence "R%u_32", 0, 9),
  // Other caller saved.
  (sequence "R%u_32", 10, 29),
  // Callee saved.
  (sequence "R%u_32", 30, 49),
  // r50 & r51 will act as fixed register under PIC, callee saved.
  R50_32, R51_32,
  // Optional frame pointer, callee saved.
  FP_32,
  // Reserved, non alloctable.
  TP_32, SP_32, LR_32, ZERO_32)>;

def CPURegs : RegisterClass<"Tile", [i64, f64], 64, (add
  (sequence "R%u", 0, 51),
  FP,
  TP, SP, LR, ZERO)>;

def SIMDRegs : RegisterClass<"Tile", [v8i8, v4i16, v2i32], 64, (add
  (sequence "R%u", 0, 51),
  FP,
  TP, SP, LR, ZERO)>;
