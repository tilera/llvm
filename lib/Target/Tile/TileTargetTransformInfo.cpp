//===-- TileTargetTransformInfo.cpp - Tile specific TTI pass --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
/// This file implements a TargetTransformInfo analysis pass specific to the
/// Tile target machine. It uses the target's detailed information to provide
/// more precise answers to certain TTI queries, while letting the target
/// independent and default TTI implementations handle the rest.
///
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "ppctti"
#include "Tile.h"
#include "TileTargetMachine.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Target/TargetLowering.h"
#include "llvm/Target/CostTable.h"
using namespace llvm;

// Declare the pass initialization routine locally as target-specific passes
// don't havve a target-wide initialization entry point, and so we rely on the
// pass constructor initialization.
namespace llvm {
void initializeTileTTIPass(PassRegistry &);
}

namespace {

class TileTTI : public ImmutablePass, public TargetTransformInfo {
  const TileTargetMachine *TM;
  const TileSubtarget *ST;
  const TileTargetLowering *TLI;

  /// Estimate the overhead of scalarizing an instruction. Insert and Extract
  /// are set if the result needs to be inserted and/or extracted from vectors.
  unsigned getScalarizationOverhead(Type *Ty, bool Insert, bool Extract) const;

public:
  TileTTI() : ImmutablePass(ID), TM(0), ST(0), TLI(0) {
    llvm_unreachable("This pass cannot be directly constructed");
  }

  TileTTI(const TileTargetMachine *TM)
      : ImmutablePass(ID), TM(TM), ST(TM->getSubtargetImpl()),
        TLI(TM->getTargetLowering()) {
    initializeTileTTIPass(*PassRegistry::getPassRegistry());
  }

  virtual void initializePass() {
    pushTTIStack(this);
  }

  virtual void finalizePass() {
    popTTIStack();
  }

  virtual void getAnalysisUsage(AnalysisUsage &AU) const {
    TargetTransformInfo::getAnalysisUsage(AU);
  }

  /// Pass identification.
  static char ID;

  /// Provide necessary pointer adjustments for the two base classes.
  virtual void *getAdjustedAnalysisPointer(const void *ID) {
    if (ID == &TargetTransformInfo::ID)
      return (TargetTransformInfo*)this;
    return this;
  }

  /// \name Scalar TTI Implementations
  /// @{
  virtual PopcntSupportKind getPopcntSupport(unsigned TyWidth) const;

  /// @}

  /// \name Vector TTI Implementations
  /// @{

  virtual unsigned getNumberOfRegisters(bool Vector) const;
  virtual unsigned getRegisterBitWidth(bool Vector) const;
  virtual unsigned getMaximumUnrollFactor() const;
  virtual unsigned getArithmeticInstrCost(unsigned Opcode, Type *Ty,
                                          OperandValueKind,
                                          OperandValueKind) const;
  virtual unsigned getShuffleCost(ShuffleKind Kind, Type *Tp,
                                  int Index, Type *SubTp) const;
  virtual unsigned getCastInstrCost(unsigned Opcode, Type *Dst,
                                    Type *Src) const;
  virtual unsigned getCmpSelInstrCost(unsigned Opcode, Type *ValTy,
                                      Type *CondTy) const;
  virtual unsigned getVectorInstrCost(unsigned Opcode, Type *Val,
                                      unsigned Index) const;
  virtual unsigned getMemoryOpCost(unsigned Opcode, Type *Src,
                                   unsigned Alignment,
                                   unsigned AddressSpace) const;

  /// @}
};

} // end anonymous namespace

INITIALIZE_AG_PASS(TileTTI, TargetTransformInfo, "Tiletti",
                   "Tile Target Transform Info", true, true, false)
char TileTTI::ID = 0;

ImmutablePass *
llvm::createTileTargetTransformInfoPass(const TileTargetMachine *TM) {
  return new TileTTI(TM);
}


//===----------------------------------------------------------------------===//
//
// Tile cost model.
//
//===----------------------------------------------------------------------===//

TileTTI::PopcntSupportKind TileTTI::getPopcntSupport(unsigned TyWidth) const {
  assert(isPowerOf2_32(TyWidth) && "Ty width must be power of 2");
  if (TyWidth <= 64)
    return PSK_FastHardware;
  return PSK_Software;
}

unsigned TileTTI::getNumberOfRegisters(bool Vector) const {
  return 64;
}

unsigned TileTTI::getRegisterBitWidth(bool Vector) const {
  return 64;
}

unsigned TileTTI::getMaximumUnrollFactor() const {
  return 2;
}

unsigned TileTTI::getArithmeticInstrCost(unsigned Opcode, Type *Ty,
                                        OperandValueKind Op1Info,
                                        OperandValueKind Op2Info) const {
  assert(TLI->InstructionOpcodeToISD(Opcode) && "Invalid opcode");

  // Fallback to the default implementation.
  return TargetTransformInfo::getArithmeticInstrCost(Opcode, Ty, Op1Info,
                                                     Op2Info);
}

unsigned TileTTI::getShuffleCost(ShuffleKind Kind, Type *Tp, int Index,
                                Type *SubTp) const {
  return TargetTransformInfo::getShuffleCost(Kind, Tp, Index, SubTp);
}

unsigned TileTTI::getCastInstrCost(unsigned Opcode, Type *Dst, Type *Src) const {
  assert(TLI->InstructionOpcodeToISD(Opcode) && "Invalid opcode");

  return TargetTransformInfo::getCastInstrCost(Opcode, Dst, Src);
}

unsigned TileTTI::getCmpSelInstrCost(unsigned Opcode, Type *ValTy,
                                    Type *CondTy) const {
  return TargetTransformInfo::getCmpSelInstrCost(Opcode, ValTy, CondTy);
}

unsigned TileTTI::getVectorInstrCost(unsigned Opcode, Type *Val,
                                    unsigned Index) const {
  assert(Val->isVectorTy() && "This must be a vector type");

  int ISD = TLI->InstructionOpcodeToISD(Opcode);
  assert(ISD && "Invalid opcode");

  // Estimated cost of a load-hit-store delay.  This was obtained
  // experimentally as a minimum needed to prevent unprofitable
  // vectorization for the paq8p benchmark.  It may need to be
  // raised further if other unprofitable cases remain.
  unsigned LHSPenalty = 12;

  // Vector element insert/extract with Altivec is very expensive,
  // because they require store and reload with the attendant
  // processor stall for load-hit-store.  Until VSX is available,
  // these need to be estimated as very costly.
  if (ISD == ISD::EXTRACT_VECTOR_ELT ||
      ISD == ISD::INSERT_VECTOR_ELT)
    return LHSPenalty +
      TargetTransformInfo::getVectorInstrCost(Opcode, Val, Index);

  return TargetTransformInfo::getVectorInstrCost(Opcode, Val, Index);
}

unsigned TileTTI::getMemoryOpCost(unsigned Opcode, Type *Src, unsigned Alignment,
                                 unsigned AddressSpace) const {
  // Legalize the type.
  std::pair<unsigned, MVT> LT = TLI->getTypeLegalizationCost(Src);
  assert((Opcode == Instruction::Load || Opcode == Instruction::Store) &&
         "Invalid Opcode");

  // Each load/store unit costs 1.
  unsigned Cost = LT.first * 1;

  // Tile in general does not support unaligned loads and stores. They'll need
  // to be decomposed based on the alignment factor.
  unsigned SrcBytes = LT.second.getStoreSize();
  if (SrcBytes && Alignment && Alignment < SrcBytes)
    Cost *= (SrcBytes/Alignment);

  return Cost;
}

