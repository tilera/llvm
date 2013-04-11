//===-- TileISelLowering.h - Tile DAG Lowering Interface --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that Tile uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#ifndef TileISELLOWERING_H
#define TileISELLOWERING_H

#include "Tile.h"
#include "TileSubtarget.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/Target/TargetLowering.h"
#include "llvm/CodeGen/CallingConvLower.h"

namespace llvm {
namespace TileISD {
enum NodeType {
  // Start the numbering from where ISD NodeType finishes.
  FIRST_NUMBER = ISD::BUILTIN_OP_END,

  // Jump and link (call)
  JmpLink,

  // r <- (r << 16) + imm16
  SAR16,

  // tls
  TLSRELAXADD0,
  TLSRELAXADD1,
  TLSGD,
  LDTLS,

  // Unary operand move
  MOVE,

  // Floating Point Branch Conditional
  FPBrcond,

  // Floating Point Compare
  FPCmp,

  // Floating Point Conditional Moves
  CMovFP_T,
  CMovFP_F,

  // Return
  Ret,

  MF,

  BRINDJT,
  VAARG_SP,
  ALLOCA_SP,
  ALLOCA_ADDR
};
}

//===--------------------------------------------------------------------===//
// TargetLowering Implementation
//===--------------------------------------------------------------------===//

class TileTargetLowering : public TargetLowering {
public:
  explicit TileTargetLowering(TileTargetMachine &TM);

  virtual bool isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const;

  virtual bool isFPImmLegal(const APFloat &Imm, EVT VT) const;

  virtual unsigned getJumpTableEncoding(void) const;

  virtual MVT getScalarShiftAmountTy(EVT LHSTy) const { return MVT::i32; }

  // Provide custom lowering hooks for some operations.
  virtual SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const;

  // This method returns the name of a target specific DAG node.
  virtual const char *getTargetNodeName(unsigned Opcode) const;

  // get the ISD::SETCC result ValueType.
  EVT getSetCCResultType(EVT VT) const;

  virtual SDValue PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const;
private:
  // Subtarget Info.
  const TileSubtarget *Subtarget;

  // Lower Operand helpers.
  SDValue LowerCallResult(
      SDValue Chain, SDValue InFlag, CallingConv::ID CallConv, bool isVarArg,
      const SmallVectorImpl<ISD::InputArg> &Ins, DebugLoc dl, SelectionDAG &DAG,
      SmallVectorImpl<SDValue> &InVals) const;

  // Lower Operand specifics.
  SDValue lowerBR_JT(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerConstantPool(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerBlockAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerGlobalTLSAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerJumpTable(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerVASTART(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerVACOPY(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerVAARG(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerFCOPYSIGN(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerFABS(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerDYNAMIC_STACKALLOC(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerMEMBARRIER(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerATOMIC_FENCE(SDValue Op, SelectionDAG &DAG) const;
  SDValue lowerFP_EXTEND(SDValue Op, SelectionDAG &DAG) const;

  virtual SDValue LowerFormalArguments(
      SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
      const SmallVectorImpl<ISD::InputArg> &Ins, DebugLoc dl, SelectionDAG &DAG,
      SmallVectorImpl<SDValue> &InVals) const;

  virtual SDValue LowerCall(TargetLowering::CallLoweringInfo &CLI,
                            SmallVectorImpl<SDValue> &InVals) const;

  virtual SDValue
  LowerReturn(SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
              const SmallVectorImpl<ISD::OutputArg> &Outs,
              const SmallVectorImpl<SDValue> &OutVals, DebugLoc dl,
              SelectionDAG &DAG) const;

  virtual MachineBasicBlock *
  EmitInstrWithCustomInserter(MachineInstr *MI, MachineBasicBlock *MBB) const;

  // Copy Tile byVal arg to registers and stack.
  void passByValArg(
      SDValue Chain, DebugLoc dl,
      SmallVector<std::pair<unsigned, SDValue>, TILEGX_AREG_NUM> &RegsToPass,
      SmallVector<SDValue, 8> &MemOpChains, SDValue StackPtr,
      MachineFrameInfo *MFI, SelectionDAG &DAG, SDValue Arg,
      const CCValAssign &VA, const ISD::ArgFlagsTy &Flags) const;

  // Inline asm support.
  ConstraintType getConstraintType(const std::string &Constraint) const;

  // Examine constraint string and operand type and determine a weight value.
  // The operand object must already have been set up with the operand type.
  ConstraintWeight getSingleConstraintMatchWeight(AsmOperandInfo &info,
                                                  const char *constraint) const;

  std::pair<unsigned, const TargetRegisterClass *>
  getRegForInlineAsmConstraint(const std::string &Constraint, EVT VT) const;
};
}

#endif // TileISELLOWERING_H
