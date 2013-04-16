//===-- TileISelLowering.cpp - Tile DAG Lowering Implementation -----------===//
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

#define DEBUG_TYPE "tile-lower"
#include "TileCallingConv.h"
#include "TileISelLowering.h"
#include "TileMachineFunction.h"
#include "TileTargetMachine.h"
#include "TileSubtarget.h"
#include "InstPrinter/TileInstPrinter.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

static SDValue GetGlobalReg(SelectionDAG &DAG, EVT Ty) {
  TileFunctionInfo *FI = DAG.getMachineFunction().getInfo<TileFunctionInfo>();
  return DAG.getRegister(FI->getGlobalBaseReg(), Ty);
}

static SDValue GetLinkReg(SelectionDAG &DAG, EVT Ty) {
  TileFunctionInfo *FI = DAG.getMachineFunction().getInfo<TileFunctionInfo>();
  return DAG.getRegister(FI->getLinkReg(), Ty);
}

const char *TileTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  case TileISD::TLSGD:
    return "TileISD::TLSGD";
  case TileISD::LDTLS:
    return "TileISD::LDTLS";
  case TileISD::TLSRELAXADD0:
    return "TileISD::TLSRELAXADD0";
  case TileISD::TLSRELAXADD1:
    return "TileISD::TLSRELAXADD1";
  case TileISD::MOVE:
    return "TileISD::MOVE";
  case TileISD::SAR16:
    return "TileISD::SAR16";
  case TileISD::JmpLink:
    return "TileISD::JmpLink";
  case TileISD::Ret:
    return "TileISD::Ret";
  case TileISD::MF:
    return "TileISD::MF";
  case TileISD::BFINS:
    return "TileISD::BFINS";
  case TileISD::BFEXTU:
    return "TileISD::BFEXTU";
  case TileISD::BRINDJT:
    return "TileISD::BRINDJT";
  case TileISD::VAARG_SP:
    return "TileISD::VAARG_SP";
  case TileISD::ALLOCA_SP:
    return "TileISD::ALLOCA_SP";
  case TileISD::ALLOCA_ADDR:
    return "TileISD::ALLOCA_ADDR";
  default:
    return NULL;
  }
}

TileTargetLowering::TileTargetLowering(TileTargetMachine &TM)
    : TargetLowering(TM, new TargetLoweringObjectFileELF()),
      Subtarget(&TM.getSubtarget<TileSubtarget>()) {

  // For divide by integer, llvm will try to expand it
  // into a sequence of instructions which use multiply
  // by a magic number.
  //
  // This cause trouble for i64 type, because this
  // algorithm needs the high part of the multiply
  // result while there is no way in tilegx to
  // fetch the high part of i64 * i64
  //
  // So, we pretend to be cheap for div / integer,
  // so that libcall will actually generated.
  setIntDivIsCheap();

  // Tile does not have i1 type, so use i32 for
  // setcc operations results (slt, sgt, ...).
  setBooleanContents(ZeroOrOneBooleanContent);
  setBooleanVectorContents(ZeroOrOneBooleanContent);

  // Set up the register classes.
  addRegisterClass(MVT::i64, &Tile::CPURegsRegClass);
  addRegisterClass(MVT::i32, &Tile::CPU32RegsRegClass);

  if (!TM.Options.UseSoftFloat) {
    addRegisterClass(MVT::f64, &Tile::CPURegsRegClass);
    addRegisterClass(MVT::f32, &Tile::CPU32RegsRegClass);
  }

  // Load extented operations for i1 types must be promoted.
  setLoadExtAction(ISD::EXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::ZEXTLOAD, MVT::i1, Promote);
  setLoadExtAction(ISD::SEXTLOAD, MVT::i1, Promote);

  // For CTPOP, because tilegx pcnt only support 64bit operand
  // we need to zero extend i32 to i64.
  setOperationAction(ISD::CTPOP, MVT::i32, Promote);

  // For SETCC, because tilegx cmplt* only support 64bit operand
  // we need to sign extend i32 to i64.
  setOperationAction(ISD::SETCC, MVT::i32, Promote);

  // TILE-Gx has partial hardware float point support.
  //   1. No dedicated float regs, reuse integer regs.
  //   2. Only support parts of float operations, mul/add etc,
  //      no support of type conversions, for example, fp->dp etc.
  //
  // So our implementation for float support is:
  //
  //   1. We pretend to have complete hardware float support.
  //      reuse integer regs as float regs.
  //
  //   2. Lower invalid float op into lib call in ISelLowering pass.
  //
  //   3. Split valid float op into corresponding inst sequences in
  //      ISelDAGToDAG pass. Because even for those valid ops, they
  //      can not be finished by a single instructions, we need a
  //      instruction combination to finish the work.
  setOperationAction(ISD::FP_EXTEND, MVT::f64, Custom);
  setOperationAction(ISD::FP_ROUND, MVT::f32, Custom);

  setLoadExtAction(ISD::EXTLOAD, MVT::f32, Expand);
  setTruncStoreAction(MVT::f64, MVT::f32, Expand);

  AddPromotedToType(ISD::SETCC, MVT::i1, MVT::i32);

  // Customize Jump Table.
  setOperationAction(ISD::BR_JT, MVT::Other, Custom);
  setOperationAction(ISD::BRCOND, MVT::Other, Custom);

  // Tile VASTART/VAARG.
  setOperationAction(ISD::VASTART, MVT::Other, Custom);
  setOperationAction(ISD::VAARG, MVT::Other, Custom);

  // Float.
  setOperationAction(ISD::SINT_TO_FP, MVT::i64, Custom);
  setOperationAction(ISD::UINT_TO_FP, MVT::i64, Custom);
  setOperationAction(ISD::FP_TO_SINT, MVT::i32, Custom);
  setOperationAction(ISD::FP_TO_SINT, MVT::i64, Custom);
  setOperationAction(ISD::FP_TO_UINT, MVT::i32, Custom);
  setOperationAction(ISD::FP_TO_UINT, MVT::i64, Custom);
  setOperationAction(ISD::FDIV, MVT::f32, Expand);
  setOperationAction(ISD::FDIV, MVT::f64, Expand);
  setOperationAction(ISD::FSQRT, MVT::f32, Expand);
  setOperationAction(ISD::FSQRT, MVT::f64, Expand);
  setOperationAction(ISD::FSIN, MVT::f32, Expand);
  setOperationAction(ISD::FSIN, MVT::f64, Expand);
  setOperationAction(ISD::FCOS, MVT::f32, Expand);
  setOperationAction(ISD::FCOS, MVT::f64, Expand);
  setOperationAction(ISD::FNEG, MVT::f32, Expand);
  setOperationAction(ISD::FNEG, MVT::f64, Expand);
  setOperationAction(ISD::FCOPYSIGN, MVT::f32, Custom);
  setOperationAction(ISD::FCOPYSIGN, MVT::f64, Custom);
  setOperationAction(ISD::FABS, MVT::f32, Custom);
  setOperationAction(ISD::FABS, MVT::f64, Custom);
  setCondCodeAction(ISD::SETUO, MVT::f32, Expand);
  setCondCodeAction(ISD::SETUO, MVT::f64, Expand);
  setCondCodeAction(ISD::SETO, MVT::f32, Expand);
  setCondCodeAction(ISD::SETO, MVT::f64, Expand);
  setOperationAction(ISD::FREM, MVT::f32, Expand);
  setOperationAction(ISD::FREM, MVT::f64, Expand);

  // Various Address Handling.
  setOperationAction(ISD::GlobalAddress, MVT::i64, Custom);
  setOperationAction(ISD::BlockAddress, MVT::i64, Custom);
  setOperationAction(ISD::GlobalTLSAddress, MVT::i64, Custom);
  setOperationAction(ISD::JumpTable, MVT::i64, Custom);
  setOperationAction(ISD::ConstantPool, MVT::i64, Custom);
  setOperationAction(ISD::SELECT, MVT::i64, Custom);

  setOperationAction(ISD::SDIV, MVT::i32, Expand);
  setOperationAction(ISD::SREM, MVT::i32, Expand);
  setOperationAction(ISD::SDIV, MVT::i64, Expand);
  setOperationAction(ISD::SREM, MVT::i64, Expand);
  setOperationAction(ISD::UDIV, MVT::i32, Expand);
  setOperationAction(ISD::UREM, MVT::i32, Expand);
  setOperationAction(ISD::UDIV, MVT::i64, Expand);
  setOperationAction(ISD::UREM, MVT::i64, Expand);
  setOperationAction(ISD::SDIVREM, MVT::i32, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i32, Expand);
  setOperationAction(ISD::SDIVREM, MVT::i64, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i64, Expand);
  setOperationAction(ISD::MULHU, MVT::i64, Expand);
  setOperationAction(ISD::MULHS, MVT::i64, Expand);
  setOperationAction(ISD::UMUL_LOHI, MVT::i64, Expand);
  setOperationAction(ISD::SMUL_LOHI, MVT::i64, Expand);

  // Expands CTXX_ZERO_UNDEF to CTXX.
  setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i32, Expand);
  setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i64, Expand);
  setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i32, Expand);
  setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i64, Expand);
  setOperationAction(ISD::ROTR, MVT::i32, Expand);
  setOperationAction(ISD::ROTR, MVT::i64, Expand);
  setOperationAction(ISD::ROTL, MVT::i32, Expand);

  // Operations not directly supported by Tile.
  setOperationAction(ISD::BR_CC, MVT::f32, Expand);
  setOperationAction(ISD::BR_CC, MVT::f64, Expand);
  setOperationAction(ISD::BR_CC, MVT::i32, Expand);
  setOperationAction(ISD::BR_CC, MVT::i64, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::Other, Expand);

  setOperationAction(ISD::EXCEPTIONADDR, MVT::i32, Expand);
  setOperationAction(ISD::EXCEPTIONADDR, MVT::i64, Expand);
  setOperationAction(ISD::EHSELECTION, MVT::i32, Expand);
  setOperationAction(ISD::EHSELECTION, MVT::i64, Expand);

  setOperationAction(ISD::VACOPY, MVT::Other, Custom);
  setOperationAction(ISD::VAEND, MVT::Other, Expand);

  // Use the default for now.
  setOperationAction(ISD::STACKSAVE, MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE, MVT::Other, Expand);

  setOperationAction(ISD::ATOMIC_LOAD, MVT::i32, Expand);
  setOperationAction(ISD::ATOMIC_LOAD, MVT::i64, Expand);
  setOperationAction(ISD::ATOMIC_STORE, MVT::i32, Expand);
  setOperationAction(ISD::ATOMIC_STORE, MVT::i64, Expand);
  setOperationAction(ISD::ATOMIC_LOAD_SUB, MVT::i32, Expand);
  setOperationAction(ISD::ATOMIC_LOAD_SUB, MVT::i64, Expand);

  setInsertFencesForAtomic(true);

  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i32, Expand);

  // Alloca support.
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i64, Custom);
  setStackPointerRegisterToSaveRestore(Tile::SP);

  setTargetDAGCombine(ISD::SELECT);

  setMinFunctionAlignment(3);

  computeRegisterProperties();

  // EH register.
  setExceptionPointerRegister(Tile::R12);
  setExceptionSelectorRegister(Tile::R13);
}

static SDValue PerformSELECTCombine(SDNode *N, SelectionDAG &DAG,
                                    TargetLowering::DAGCombinerInfo &DCI,
                                    const TileSubtarget *Subtarget) {
  if (DCI.isBeforeLegalizeOps())
    return SDValue();

  SDValue SetCC = N->getOperand(0);

  if ((SetCC.getOpcode() != ISD::SETCC) ||
      !SetCC.getOperand(0).getValueType().isInteger())
    return SDValue();

  SDValue False = N->getOperand(2);
  EVT FalseTy = False.getValueType();

  if (!FalseTy.isInteger())
    return SDValue();

  ConstantSDNode *CN = dyn_cast<ConstantSDNode>(False);

  if (!CN || CN->getZExtValue())
    return SDValue();

  const DebugLoc DL = N->getDebugLoc();
  ISD::CondCode CC = cast<CondCodeSDNode>(SetCC.getOperand(2))->get();
  SDValue True = N->getOperand(1);

  SetCC = DAG.getSetCC(DL, SetCC.getValueType(), SetCC.getOperand(0),
                       SetCC.getOperand(1), ISD::getSetCCInverse(CC, true));

  return DAG.getNode(ISD::SELECT, DL, FalseTy, SetCC, False, True);
}

SDValue
TileTargetLowering::PerformDAGCombine(SDNode *N, DAGCombinerInfo &DCI) const {
  SelectionDAG &DAG = DCI.DAG;
  unsigned Opc = N->getOpcode();

  switch (Opc) {
  default:
    break;
  case ISD::SELECT:
    return PerformSELECTCombine(N, DAG, DCI, Subtarget);
  }

  return SDValue();
}

SDValue
TileTargetLowering::LowerOperation(SDValue Op, SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  case ISD::BR_JT:
    return lowerBR_JT(Op, DAG);
  case ISD::BRCOND:
    return Op;
  case ISD::ConstantPool:
    return lowerConstantPool(Op, DAG);
  case ISD::GlobalAddress:
    return lowerGlobalAddress(Op, DAG);
  case ISD::BlockAddress:
    return lowerBlockAddress(Op, DAG);
  case ISD::GlobalTLSAddress:
    return lowerGlobalTLSAddress(Op, DAG);
  case ISD::JumpTable:
    return lowerJumpTable(Op, DAG);
  case ISD::SELECT:
    return Op;
  case ISD::VASTART:
    return lowerVASTART(Op, DAG);
  case ISD::VACOPY:
    return lowerVACOPY(Op, DAG);
  case ISD::VAARG:
    return lowerVAARG(Op, DAG);
  case ISD::FCOPYSIGN:
    return lowerFCOPYSIGN(Op, DAG);
  case ISD::FABS:
    return lowerFABS(Op, DAG);
  case ISD::FRAMEADDR:
    return lowerFRAMEADDR(Op, DAG);
  case ISD::RETURNADDR:
    return lowerRETURNADDR(Op, DAG);
  case ISD::DYNAMIC_STACKALLOC:
    return lowerDYNAMIC_STACKALLOC(Op, DAG);
  case ISD::FP_ROUND:
  case ISD::FP_EXTEND:
    return lowerFpFpConv(Op, DAG);
  case ISD::SINT_TO_FP:
  case ISD::UINT_TO_FP:
  case ISD::FP_TO_SINT:
  case ISD::FP_TO_UINT:
    return lowerFpIntConv(Op, DAG);
  }
  return SDValue();
}

//===----------------------------------------------------------------------===//
//  Lower helper functions
//===----------------------------------------------------------------------===//

// This helper function adds the specified physical register to the
// MachineFunction as a live in value.  It also creates a corresponding
// virtual register for it.
static unsigned
AddLiveIn(MachineFunction &MF, unsigned PReg, const TargetRegisterClass *RC) {
  assert(RC->contains(PReg) && "Not the correct regclass!");
  unsigned VReg = MF.getRegInfo().createVirtualRegister(RC);
  MF.getRegInfo().addLiveIn(PReg, VReg);
  return VReg;
}

MachineBasicBlock *TileTargetLowering::EmitInstrWithCustomInserter(
    MachineInstr *MI, MachineBasicBlock *BB) const {
  switch (MI->getOpcode()) {
  default:
    llvm_unreachable("Unexpected instr type to insert");
  }
}

//===----------------------------------------------------------------------===//
//  Misc Lower Operation implementation.
//===----------------------------------------------------------------------===//
SDValue TileTargetLowering::lowerBR_JT(SDValue Op, SelectionDAG &DAG) const {
  SDValue Chain = Op->getOperand(0);
  SDValue Table = Op->getOperand(1);
  SDValue Index = Op->getOperand(2);
  DebugLoc dl = Op.getDebugLoc();

  EVT PTy = getPointerTy();

  JumpTableSDNode *JT = cast<JumpTableSDNode>(Table);
  SDValue JTI = DAG.getTargetJumpTable(JT->getIndex(), PTy);

  Index = DAG.getNode(ISD::MUL, dl, PTy, Index, DAG.getConstant(8, PTy));
  SDValue Addr = DAG.getNode(ISD::ADD, dl, PTy, Index, Table);

  EVT MemVT = EVT::getIntegerVT(*DAG.getContext(), 64);
  SDValue Temp = DAG.getExtLoad(ISD::SEXTLOAD, dl, PTy, Chain, Addr,
                                MachinePointerInfo::getJumpTable(), MemVT,
                                false, false, 0);
  Addr = Temp;
  if (getTargetMachine().getRelocationModel() == Reloc::PIC_) {
    // For PIC, the sequence is:
    // BRIND(load(Jumptable + index) + RelocBase)
    // RelocBase can be JumpTable, GOT or some sort of global base..
    Addr = DAG.getNode(ISD::ADD, dl, PTy, Addr,
                       getPICJumpTableRelocBase(Table, DAG));
  }
  return DAG.getNode(TileISD::BRINDJT, dl, MVT::Other, Temp.getValue(1), Addr,
                     JTI);
}

SDValue
TileTargetLowering::lowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const {
  DebugLoc dl = Op.getDebugLoc();
  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();

  // NON-PIC
  if (getTargetMachine().getRelocationModel() != Reloc::PIC_) {
    SDValue GlobalAddrHigh =
        DAG.getTargetGlobalAddress(GV, dl, MVT::i64, 0, TileII::MO_HW2_LAST);
    SDValue GlobalAddrMiddle =
        DAG.getTargetGlobalAddress(GV, dl, MVT::i64, 0, TileII::MO_HW1);
    SDValue GlobalAddrLow =
        DAG.getTargetGlobalAddress(GV, dl, MVT::i64, 0, TileII::MO_HW0);

    // >=32 part
    SDValue Addr = DAG.getNode(TileISD::MOVE, dl, MVT::i64, GlobalAddrHigh);
    // >=16 part
    Addr = DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, GlobalAddrMiddle);
    // >=0 part
    return DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, GlobalAddrLow);
  }

  // PIC
  unsigned char Flag1 = TileII::MO_HW1_LAST_GOT;
  unsigned char Flag2 = TileII::MO_HW0_GOT;
  SDValue BaseReg = GetGlobalReg(DAG, MVT::i64);
  bool Internal =
      GV->hasInternalLinkage() || (GV->hasLocalLinkage() && !isa<Function>(GV));
  if (Internal) {
    Flag1 = TileII::MO_HW1_LAST_PIC;
    Flag2 = TileII::MO_HW0_PIC;
    BaseReg = GetLinkReg(DAG, MVT::i64);
  }

  SDValue GotEntryHigh = DAG.getTargetGlobalAddress(GV, dl, MVT::i64, 0, Flag1);
  SDValue GotEntryLow = DAG.getTargetGlobalAddress(GV, dl, MVT::i64, 0, Flag2);
  SDValue Addr = DAG.getNode(TileISD::MOVE, dl, MVT::i64, GotEntryHigh);
  Addr = DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, GotEntryLow);

  if (Internal)
    return DAG.getNode(ISD::ADD, dl, MVT::i64, BaseReg, Addr);

  Addr = DAG.getNode(ISD::ADD, dl, MVT::i64, BaseReg, Addr);
  return DAG.getLoad(MVT::i64, dl, DAG.getEntryNode(), Addr,
                     MachinePointerInfo(), false, false, false, 0);
}

SDValue
TileTargetLowering::lowerBlockAddress(SDValue Op, SelectionDAG &DAG) const {
  const BlockAddress *BA = cast<BlockAddressSDNode>(Op)->getBlockAddress();
  DebugLoc dl = Op.getDebugLoc();

  // NON-PIC
  if (getTargetMachine().getRelocationModel() != Reloc::PIC_) {
    SDValue BlockAddrHigh =
        DAG.getTargetBlockAddress(BA, MVT::i64, 0, TileII::MO_HW2_LAST);
    SDValue BlockAddrMiddle =
        DAG.getTargetBlockAddress(BA, MVT::i64, 0, TileII::MO_HW1);
    SDValue BlockAddrLow =
        DAG.getTargetBlockAddress(BA, MVT::i64, 0, TileII::MO_HW0);

    // >=32 part
    SDValue Addr = DAG.getNode(TileISD::MOVE, dl, MVT::i64, BlockAddrHigh);
    // >=16 part
    Addr = DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, BlockAddrMiddle);
    // >=0 part
    return DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, BlockAddrLow);
  }

  // PIC
  unsigned char Flag1 = TileII::MO_HW1_LAST_PIC;
  unsigned char Flag2 = TileII::MO_HW0_PIC;
  SDValue BaseReg = GetLinkReg(DAG, MVT::i64);

  SDValue GotEntryHigh = DAG.getTargetBlockAddress(BA, MVT::i64, 0, Flag1);
  SDValue GotEntryLow = DAG.getTargetBlockAddress(BA, MVT::i64, 0, Flag2);
  SDValue Addr = DAG.getNode(TileISD::MOVE, dl, MVT::i64, GotEntryHigh);
  Addr = DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, GotEntryLow);

  return DAG.getNode(ISD::ADD, dl, MVT::i64, BaseReg, Addr);
}

SDValue
TileTargetLowering::lowerGlobalTLSAddress(SDValue Op, SelectionDAG &DAG) const {
  GlobalAddressSDNode *GA = cast<GlobalAddressSDNode>(Op);
  DebugLoc dl = GA->getDebugLoc();
  const GlobalValue *GV = GA->getGlobal();
  EVT PtrVT = getPointerTy();
  TLSModel::Model Model = getTargetMachine().getTLSModel(GA->getGlobal());
  SDValue TAddrHigh, TAddrLow, TRelaxA, TRelaxB, RetNode;

  if (Model == TLSModel::GeneralDynamic || Model == TLSModel::LocalDynamic) {
    TAddrHigh = DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0,
                                           TileII::MO_HW1_LAST_TLS_GD);
    TAddrLow =
        DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_HW0_TLS_GD);
    TRelaxA = DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_TLS_ADD);
    TRelaxB =
        DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_TLS_GD_ADD);
    RetNode = DAG.getNode(TileISD::MOVE, dl, PtrVT, TAddrHigh);
    RetNode = DAG.getNode(TileISD::TLSGD, dl, PtrVT, RetNode, TAddrLow);
    RetNode = DAG.getNode(TileISD::TLSRELAXADD0, dl, PtrVT,
                          GetGlobalReg(DAG, PtrVT), TRelaxA, RetNode);

    unsigned PtrSize = PtrVT.getSizeInBits();
    IntegerType *PtrTy = Type::getIntNTy(*DAG.getContext(), PtrSize);
    ArgListTy Args;
    ArgListEntry Entry;
    Entry.Node = RetNode;
    Entry.Ty = PtrTy;
    Args.push_back(Entry);
    TargetLowering::CallLoweringInfo CLI(
        DAG.getEntryNode(), PtrTy, false, false, false, false, 0,
        CallingConv::C, /*IsTailCall=*/ false, /*DoesNotRet=*/ false,
        /*IsReturnValueUsed=*/ true, Op, Args, DAG, dl);
    std::pair<SDValue, SDValue> CallResult = LowerCallTo(CLI);

    SDValue Ret = CallResult.first;
    Ret = DAG.getNode(TileISD::TLSRELAXADD1, dl, PtrVT, Ret, TRelaxB);
    return Ret;
  }

  if (Model == TLSModel::InitialExec) {
    // Initial Exec TLS Model
    TAddrHigh = DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0,
                                           TileII::MO_HW1_LAST_TLS_IE);
    TAddrLow =
        DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_HW0_TLS_IE);
    TRelaxA = DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_TLS_ADD);
    TRelaxB =
        DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_TLS_IE_LOAD);
    RetNode = DAG.getNode(TileISD::MOVE, dl, PtrVT, TAddrHigh);
    RetNode = DAG.getNode(TileISD::TLSGD, dl, PtrVT, RetNode, TAddrLow);
    RetNode = DAG.getNode(TileISD::TLSRELAXADD0, dl, PtrVT,
                          GetGlobalReg(DAG, PtrVT), TRelaxA, RetNode);
    RetNode = DAG.getNode(TileISD::LDTLS, dl, PtrVT, RetNode, TRelaxB);
  } else if (Model == TLSModel::LocalExec) {
    // Local Exec TLS Model
    TAddrHigh = DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0,
                                           TileII::MO_HW1_LAST_TLS_LE);
    TAddrLow =
        DAG.getTargetGlobalAddress(GV, dl, PtrVT, 0, TileII::MO_HW0_TLS_LE);
    RetNode = DAG.getNode(TileISD::MOVE, dl, PtrVT, TAddrHigh);
    RetNode = DAG.getNode(TileISD::TLSGD, dl, PtrVT, RetNode, TAddrLow);
  } else
    llvm_unreachable("bogus TLS Model");

  RetNode = DAG.getNode(ISD::ADD, dl, PtrVT, RetNode,
                        DAG.getRegister(Tile::TP, PtrVT));
  return RetNode;
}

SDValue
TileTargetLowering::lowerJumpTable(SDValue Op, SelectionDAG &DAG) const {
  SDValue Temp, JTI, JTILo;
  DebugLoc dl = Op.getDebugLoc();
  bool IsPIC = getTargetMachine().getRelocationModel() == Reloc::PIC_;
  EVT PtrVT = Op.getValueType();
  JumpTableSDNode *JT = cast<JumpTableSDNode>(Op);

  unsigned char Flag1 = IsPIC ? TileII::MO_HW1_LAST_PIC : TileII::MO_HW2_LAST;
  unsigned char Flag2 = IsPIC ? TileII::MO_HW0_PIC : TileII::MO_HW1;

  JTI = DAG.getTargetJumpTable(JT->getIndex(), PtrVT, Flag1);
  Temp = DAG.getNode(TileISD::MOVE, dl, PtrVT, JTI);
  Temp = Temp.getValue(0);
  JTI = DAG.getTargetJumpTable(JT->getIndex(), PtrVT, Flag2);
  Temp = DAG.getNode(TileISD::SAR16, dl, PtrVT, Temp, JTI);
  Temp = Temp.getValue(0);

  if (!IsPIC) {
    JTI = DAG.getTargetJumpTable(JT->getIndex(), PtrVT, TileII::MO_HW0);
    return DAG.getNode(TileISD::SAR16, dl, PtrVT, Temp, JTI);
  }

  return DAG.getNode(ISD::ADD, dl, PtrVT, Temp, GetLinkReg(DAG, PtrVT));
}

SDValue
TileTargetLowering::lowerConstantPool(SDValue Op, SelectionDAG &DAG) const {
  SDValue ResNode;
  ConstantPoolSDNode *N = cast<ConstantPoolSDNode>(Op);
  const Constant *C = N->getConstVal();
  DebugLoc dl = Op.getDebugLoc();
  EVT ValTy = Op.getValueType();

  // NON-PIC
  if (getTargetMachine().getRelocationModel() != Reloc::PIC_) {
    SDValue AddrHigh = DAG.getTargetConstantPool(
        C, ValTy, N->getAlignment(), N->getOffset(), TileII::MO_HW2_LAST);
    SDValue AddrMiddle = DAG.getTargetConstantPool(
        C, ValTy, N->getAlignment(), N->getOffset(), TileII::MO_HW1);
    SDValue AddrLow = DAG.getTargetConstantPool(C, ValTy, N->getAlignment(),
                                                N->getOffset(), TileII::MO_HW0);

    // >=32 part
    SDValue Addr = DAG.getNode(TileISD::MOVE, dl, ValTy, AddrHigh);
    // >=16 part
    Addr = DAG.getNode(TileISD::SAR16, dl, ValTy, Addr, AddrMiddle);
    // >=0 part
    return DAG.getNode(TileISD::SAR16, dl, ValTy, Addr, AddrLow);
  }

  // PIC
  unsigned char Flag1 = TileII::MO_HW1_LAST_PIC;
  unsigned char Flag2 = TileII::MO_HW0_PIC;
  SDValue BaseReg = GetLinkReg(DAG, MVT::i64);

  SDValue RelHigh = DAG.getTargetConstantPool(C, ValTy, N->getAlignment(),
                                              N->getOffset(), Flag1);
  SDValue RelLow = DAG.getTargetConstantPool(C, ValTy, N->getAlignment(),
                                             N->getOffset(), Flag2);
  SDValue Addr = DAG.getNode(TileISD::MOVE, dl, MVT::i64, RelHigh);
  SDValue GotOff = DAG.getNode(TileISD::SAR16, dl, MVT::i64, Addr, RelLow);

  return DAG.getNode(ISD::ADD, dl, MVT::i64, BaseReg, GotOff);
}

SDValue TileTargetLowering::lowerVASTART(SDValue Op, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();
  TileFunctionInfo *FuncInfo = MF.getInfo<TileFunctionInfo>();

  DebugLoc dl = Op.getDebugLoc();
  SDValue FI =
      DAG.getFrameIndex(FuncInfo->getVarArgsFrameIndex(), getPointerTy());

  // VASTART just stores the address of the VarArgsFrameIndex slot into the
  // memory location argument.
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  SDValue Chain = DAG.getStore(Op.getOperand(0), dl, FI, Op.getOperand(1),
                               MachinePointerInfo(SV), false, false, 0);

  // We need to keep the original sp.
  SDValue ORIG_SP = DAG.getNode(TileISD::VAARG_SP, dl, getPointerTy(),
                                DAG.getRegister(Tile::SP, getPointerTy()),
                                DAG.getConstant(0, getPointerTy()));
  FI = DAG.getNode(ISD::ADD, dl, getPointerTy(), Op.getOperand(1),
                   DAG.getConstant(8, getPointerTy()));
  return DAG.getStore(Chain, dl, ORIG_SP, FI, MachinePointerInfo(SV), false,
                      false, 0);

}

SDValue TileTargetLowering::lowerVACOPY(SDValue Op, SelectionDAG &DAG) const {
  // For Tile, va_list is a struct {
  //   void * val;
  //   void * sp_at_entry;
  //   }
  SDValue Chain = Op.getOperand(0);
  SDValue DstPtr = Op.getOperand(1);
  SDValue SrcPtr = Op.getOperand(2);
  const Value *DstSV = cast<SrcValueSDNode>(Op.getOperand(3))->getValue();
  const Value *SrcSV = cast<SrcValueSDNode>(Op.getOperand(4))->getValue();
  DebugLoc DL = Op.getDebugLoc();

  return DAG.getMemcpy(Chain, DL, DstPtr, SrcPtr, DAG.getIntPtrConstant(16), 8,
                       /*isVolatile*/ false, false, MachinePointerInfo(DstSV),
                       MachinePointerInfo(SrcSV));
}

SDValue TileTargetLowering::lowerVAARG(SDValue Op, SelectionDAG &DAG) const {
  SDNode *Node = Op.getNode();
  EVT VT = Node->getValueType(0);
  SDValue InChain = Node->getOperand(0);
  SDValue VAListPtr = Node->getOperand(1);
  const Value *SV = cast<SrcValueSDNode>(Node->getOperand(2))->getValue();
  DebugLoc dl = Node->getDebugLoc();

  // For Tile, because the low 16bytes of stack frame are
  // reserved for special purpose, for va_arg, if the next
  // argument is on stack, then it should skip the 16byte
  // reserved zone. We kept the original stack pointer for
  // comparision purpose, so that we could know if we have
  // meet the stack boundary.
  //
  // va_arg
  //   |
  //   |
  //   V
  //   1. get va_list_pointer
  //   2. get original_sp
  //    3. if (va_list_pointer == original_sp) {
  //       // meet the stack boundary, the arguments
  //       // are on stack since this point.
  //         va_list_pointer += 16;
  //       }
  SDValue SPPtr = DAG.getNode(ISD::ADD, dl, getPointerTy(), VAListPtr,
                              DAG.getConstant(8, getPointerTy()));

  SDValue VAList = DAG.getLoad(getPointerTy(), dl, InChain, VAListPtr,
                               MachinePointerInfo(SV), false, false, false, 0);

  SDValue SPSave = DAG.getLoad(getPointerTy(), dl, VAList.getValue(1), SPPtr,
                               MachinePointerInfo(SV), false, false, false, 0);

  SDValue NextPtr = DAG.getNode(ISD::ADD, dl, getPointerTy(), VAList,
                                DAG.getConstant(8, getPointerTy()));

  SDValue Cond = DAG.getNode(ISD::XOR, dl, getPointerTy(), SPSave, NextPtr);

  SDValue ADJPtr = DAG.getNode(ISD::ADD, dl, getPointerTy(), VAList,
                               DAG.getConstant(24, getPointerTy()));

  ADJPtr = DAG.getNode(ISD::SELECT, dl, getPointerTy(), Cond, NextPtr, ADJPtr);

  // Store the incremented VAList to the legalized pointer.
  InChain = DAG.getStore(VAList.getValue(1), dl, ADJPtr, VAListPtr,
                         MachinePointerInfo(SV), false, false, 0);

  return DAG.getLoad(VT, dl, InChain, VAList, MachinePointerInfo(), false,
                     false, false, 0);
}

SDValue
TileTargetLowering::lowerFCOPYSIGN(SDValue Op, SelectionDAG &DAG) const {
  unsigned WidthX = Op.getOperand(0).getValueSizeInBits();
  unsigned WidthY = Op.getOperand(1).getValueSizeInBits();
  EVT TyX = MVT::getIntegerVT(WidthX), TyY = MVT::getIntegerVT(WidthY);
  uint64_t SignBitPosX = (TyX == MVT::i64) ? 63 : 31;
  uint64_t SignBitPosY = (TyY == MVT::i64) ? 63 : 31;
  SDValue StartPosX = DAG.getConstant(SignBitPosX, TyX);
  SDValue EndPosX = DAG.getConstant(SignBitPosX, TyX);
  SDValue StartPosY = DAG.getConstant(SignBitPosY, TyY);
  SDValue EndPosY = DAG.getConstant(SignBitPosY, TyY);
  DebugLoc DL = Op.getDebugLoc();

  // Bitcast to integer nodes.
  SDValue X = DAG.getNode(ISD::BITCAST, DL, TyX, Op.getOperand(0));
  SDValue Y = DAG.getNode(ISD::BITCAST, DL, TyY, Op.getOperand(1));

  // ext  S, Y, width(Y) - 1, 1  ; extract the sign bit from Y
  // ins  X, S, width(X) - 1, 1  ; update the sign bit to X
  SDValue Sign = DAG.getNode(TileISD::BFEXTU, DL, TyX, Y, StartPosY, EndPosY);

  SDValue I = DAG.getNode(TileISD::BFINS, DL, TyX, Sign, StartPosX, EndPosX, X);
  return DAG.getNode(ISD::BITCAST, DL, Op.getOperand(0).getValueType(), I);
}

SDValue TileTargetLowering::lowerFABS(SDValue Op, SelectionDAG &DAG) const {
  SDValue Res;
  EVT Ty = Op.getValueType();
  EVT CastTy = (Ty == MVT::f64) ? MVT::i64 : MVT::i32;
  uint64_t SignBitPos = (Ty == MVT::f64) ? 63 : 31;
  SDValue StartPos = DAG.getConstant(SignBitPos, CastTy);
  SDValue EndPos = DAG.getConstant(SignBitPos, CastTy);
  SDValue ZeroV =
      DAG.getRegister((Ty == MVT::f64) ? Tile::ZERO : Tile::ZERO_32, CastTy);
  DebugLoc DL = Op.getDebugLoc();

  // Bitcast to integer node.
  SDValue X = DAG.getNode(ISD::BITCAST, DL, CastTy, Op.getOperand(0));

  Res = DAG.getNode(TileISD::BFINS, DL, CastTy, ZeroV, StartPos, EndPos, X);

  return DAG.getNode(ISD::BITCAST, DL, Ty, Res);
}

SDValue
TileTargetLowering::lowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const {
  // Check the depth.
  assert((cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() == 0) &&
         "Frame address can only be determined for current frame.");

  MachineFrameInfo *MFI = DAG.getMachineFunction().getFrameInfo();
  MFI->setFrameAddressIsTaken(true);
  EVT VT = Op.getValueType();
  DebugLoc dl = Op.getDebugLoc();
  SDValue FrameAddr = DAG.getCopyFromReg(DAG.getEntryNode(), dl, Tile::FP, VT);
  return FrameAddr;
}

SDValue
TileTargetLowering::lowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const {
  // Check the depth.
  assert((cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() == 0) &&
         "Return address can be determined only for current frame.");

  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  MVT VT = Op.getSimpleValueType();
  MFI->setReturnAddressIsTaken(true);

  // Return LR, which contains the return address. Mark it an implicit live-in.
  unsigned Reg = MF.addLiveIn(Tile::LR, getRegClassFor(VT));
  return DAG.getCopyFromReg(DAG.getEntryNode(), Op.getDebugLoc(), Reg, VT);
}

SDValue TileTargetLowering::lowerDYNAMIC_STACKALLOC(SDValue Op,
                                                    SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0); // Legalize the chain.
  SDValue Size = Op.getOperand(1);  // Legalize the size.
  DebugLoc dl = Op.getDebugLoc();

  unsigned SPReg = Tile::SP;
  SDValue SP = DAG.getCopyFromReg(Chain, dl, SPReg, MVT::i64);
  SDValue NewSP = DAG.getNode(ISD::SUB, dl, MVT::i64, SP, Size); // Value

  SDValue RESERV0 = DAG.getLoad(MVT::i64, dl, SP.getValue(1), SP,
                                MachinePointerInfo(), false, false, false, 0);

  SDValue RESERV1_ADDR =
      DAG.getNode(ISD::ADD, dl, MVT::i64, SP, DAG.getConstant(8, MVT::i64));

  SDValue RESERV1 = DAG.getLoad(MVT::i64, dl, RESERV0.getValue(1), RESERV1_ADDR,
                                MachinePointerInfo(), false, false, false, 0);

  SDValue PlaceHolderSP =
      DAG.getNode(TileISD::ALLOCA_SP, dl, MVT::i64,
                  DAG.getRegister(Tile::ZERO, getPointerTy()), NewSP);

  Chain = DAG.getStore(RESERV1.getValue(1), dl, RESERV0, PlaceHolderSP,
                       MachinePointerInfo(), false, false, false, 0);

  RESERV1_ADDR = DAG.getNode(ISD::ADD, dl, MVT::i64, PlaceHolderSP,
                             DAG.getConstant(8, MVT::i64));

  Chain = DAG.getStore(Chain, dl, RESERV1, RESERV1_ADDR, MachinePointerInfo(),
                       false, false, false, 0);

  Chain = DAG.getCopyToReg(Chain, dl, SPReg, NewSP);

  // The resultant pointer should be lift up by 16bytes, to skip
  // the 16 bytes tilegx special zone.
  SDValue NewVal = DAG.getNode(TileISD::ALLOCA_ADDR, dl, MVT::i64, NewSP,
                               DAG.getConstant(16, MVT::i64));
  SDValue Ops[2] = { NewVal, Chain };
  return DAG.getMergeValues(Ops, 2, dl);
}

//===----------------------------------------------------------------------===//
//                      Soft Float Implementation
//===----------------------------------------------------------------------===//
SDValue TileTargetLowering::lowerFpFpConv(SDValue Op, SelectionDAG &DAG) const {
  RTLIB::Libcall LC;
  if (Op.getOpcode() == ISD::FP_ROUND)
    LC = RTLIB::getFPROUND(Op.getOperand(0).getValueType(), Op.getValueType());
  else
    LC = RTLIB::getFPEXT(Op.getOperand(0).getValueType(), Op.getValueType());

  SDValue SrcVal = Op.getOperand(0);
  return makeLibCall(DAG, LC, Op.getValueType(), &SrcVal, 1, false,
                     Op.getDebugLoc());
}

SDValue
TileTargetLowering::lowerFpIntConv(SDValue Op, SelectionDAG &DAG) const {
  RTLIB::Libcall LC;
  switch (Op.getOpcode()) {
  case ISD::FP_TO_SINT:
    LC = RTLIB::getFPTOSINT(Op.getOperand(0).getValueType(), Op.getValueType());
    break;
  case ISD::FP_TO_UINT:
    LC = RTLIB::getFPTOUINT(Op.getOperand(0).getValueType(), Op.getValueType());
    break;
  case ISD::SINT_TO_FP:
    if (Op.getOperand(0).getValueType() == MVT::i32)
      return Op;
    LC = RTLIB::getSINTTOFP(Op.getOperand(0).getValueType(), Op.getValueType());
    break;
  case ISD::UINT_TO_FP:
    if (Op.getOperand(0).getValueType() == MVT::i32)
      return Op;
    LC = RTLIB::getUINTTOFP(Op.getOperand(0).getValueType(), Op.getValueType());
    break;
  default:
    llvm_unreachable("lowerFpIntConv: unexpected type met!");
  }

  SDValue SrcVal = Op.getOperand(0);
  return makeLibCall(DAG, LC, Op.getValueType(), &SrcVal, 1, false,
                     Op.getDebugLoc());
}

//===----------------------------------------------------------------------===//
//                      Calling Convention Implementation
//===----------------------------------------------------------------------===//
static const uint16_t TileIntRegs[TILEGX_AREG_NUM] = {
  Tile::R0, Tile::R1, Tile::R2, Tile::R3, Tile::R4, Tile::R5, Tile::R6,
  Tile::R7, Tile::R8, Tile::R9
};

static bool
CC_TileByval(unsigned ValNo, MVT ValVT, MVT LocVT, CCValAssign::LocInfo LocInfo,
             ISD::ArgFlagsTy ArgFlags, CCState &State) {
  unsigned Align = std::max(ArgFlags.getByValAlign(), (unsigned) 8);
  unsigned Size = RoundUpToAlignment(ArgFlags.getByValSize(), Align);
  unsigned FirstIdx = State.getFirstUnallocated(TileIntRegs, TILEGX_AREG_NUM);

  assert(Align <= 16 && "Cannot handle alignments larger than 16.");

  // If byval is 16-byte aligned, the first arg register must be even.
  if ((Align == 16) && (FirstIdx % 2)) {
    State.AllocateReg(TileIntRegs[FirstIdx]);
    ++FirstIdx;
  }

  // Mark the registers allocated.
  for (unsigned I = FirstIdx; Size && (I < TILEGX_AREG_NUM); Size -= 8, ++I)
    State.AllocateReg(TileIntRegs[I]);

  // Allocate space on caller's stack.
  unsigned Offset = State.AllocateStack(Size, Align);

  if (FirstIdx < TILEGX_AREG_NUM)
    State.addLoc(CCValAssign::getReg(ValNo, ValVT, TileIntRegs[FirstIdx], LocVT,
                                     LocInfo));
  else
    State.addLoc(CCValAssign::getMem(ValNo, ValVT, Offset, LocVT, LocInfo));

  return true;
}

#include "TileGenCallingConv.inc"

static void AnalyzeTileCallOperands(
    CCState &CCInfo, const SmallVectorImpl<ISD::OutputArg> &Outs) {
  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    MVT ArgVT = Outs[i].VT;
    ISD::ArgFlagsTy ArgFlags = Outs[i].Flags;
    bool R;

    R = CC_Tile(i, ArgVT, ArgVT, CCValAssign::Full, ArgFlags, CCInfo);

    if (R) {
#ifndef NDEBUG
      dbgs() << "Call operand #" << i << " has unhandled type "
             << EVT(ArgVT).getEVTString();
#endif
      llvm_unreachable("Unexpected call operand type.");
    }
  }
}

//===----------------------------------------------------------------------===//
//                  Call Calling Convention Implementation
//===----------------------------------------------------------------------===//

// Copy Tile byVal arg to registers and stack.
void TileTargetLowering::passByValArg(
    SDValue Chain, DebugLoc dl,
    SmallVector<std::pair<unsigned, SDValue>, TILEGX_AREG_NUM> &RegsToPass,
    SmallVector<SDValue, 8> &MemOpChains, SDValue StackPtr,
    MachineFrameInfo *MFI, SelectionDAG &DAG, SDValue Arg,
    const CCValAssign &VA, const ISD::ArgFlagsTy &Flags) const {
  unsigned ByValSize = Flags.getByValSize();
  unsigned Align = std::max(Flags.getByValAlign(), (unsigned) 8);
  bool IsRegLoc = VA.isRegLoc();
  unsigned Offset = 0; // Offset in # of bytes from the beginning of struct.
  unsigned LocMemOffset = TILEGX_BZONE_SIZE;
  unsigned MemCpySize = ByValSize;
  EVT PtrTy = getPointerTy();

  if (IsRegLoc) {
    const uint16_t *Reg =
        std::find(TileIntRegs, TileIntRegs + TILEGX_AREG_NUM, VA.getLocReg());
    const uint16_t *RegEnd = TileIntRegs + TILEGX_AREG_NUM;

    // Copy double words to registers.
    for (;(Reg != RegEnd) && (ByValSize >= Offset + 8); ++Reg, Offset += 8) {
      SDValue LoadPtr =
          DAG.getNode(ISD::ADD, dl, PtrTy, Arg, DAG.getConstant(Offset, PtrTy));
      SDValue LoadVal =
          DAG.getLoad(MVT::i64, dl, Chain, LoadPtr, MachinePointerInfo(), false,
                      false, false, Align);
      MemOpChains.push_back(LoadVal.getValue(1));
      RegsToPass.push_back(std::make_pair(*Reg, LoadVal));
    }

    // Return if the struct has been fully copied.
    if (!(MemCpySize = ByValSize - Offset))
      return;

    // If there is an argument register available, copy the remainder of the
    // byval argument with sub-doubleword loads and shifts.
    if (Reg != RegEnd) {
      assert((ByValSize < Offset + 8) &&
             "Size of the remainder should be smaller than 8-byte.");
      SDValue Val;
      for (unsigned LoadSize = 4; Offset < ByValSize; LoadSize /= 2) {
        unsigned RemSize = ByValSize - Offset;

        if (RemSize < LoadSize)
          continue;

        SDValue LoadPtr = DAG.getNode(ISD::ADD, dl, PtrTy, Arg,
                                      DAG.getConstant(Offset, PtrTy));
        SDValue LoadVal = DAG.getExtLoad(
            ISD::ZEXTLOAD, dl, MVT::i64, Chain, LoadPtr, MachinePointerInfo(),
            MVT::getIntegerVT(LoadSize * 8), false, false, Align);
        MemOpChains.push_back(LoadVal.getValue(1));

        // Offset in number of bits from double word boundary.
        unsigned OffsetDW = (Offset % 8) * 8;
        unsigned Shamt = OffsetDW;
        SDValue Shift = DAG.getNode(ISD::SHL, dl, MVT::i64, LoadVal,
                                    DAG.getConstant(Shamt, MVT::i32));

        Val = Val.getNode() ? DAG.getNode(ISD::OR, dl, MVT::i64, Val, Shift)
                            : Shift;
        Offset += LoadSize;
        Align = std::min(Align, LoadSize);
      }

      RegsToPass.push_back(std::make_pair(*Reg, Val));
      return;
    }
  } else
    LocMemOffset = VA.getLocMemOffset();

  assert(MemCpySize && "MemCpySize must not be zero.");

  // Copy remainder of byval arg to it with memcpy.
  SDValue Src =
      DAG.getNode(ISD::ADD, dl, PtrTy, Arg, DAG.getConstant(Offset, PtrTy));
  SDValue Dst = DAG.getNode(ISD::ADD, dl, PtrTy, StackPtr,
                            DAG.getConstant(LocMemOffset, PtrTy));

  Chain = DAG.getMemcpy(Chain, dl, Dst, Src, DAG.getConstant(MemCpySize, PtrTy),
                        Align, /*isVolatile=*/ false, /*AlwaysInline=*/ false,
                        MachinePointerInfo(0), MachinePointerInfo(0));

  MemOpChains.push_back(Chain);
}

// Functions arguments are copied from virtual regs to
// (physical regs)/(stack frame), CALLSEQ_START and CALLSEQ_END are emitted.
SDValue TileTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                      SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  DebugLoc &dl = CLI.DL;
  SmallVector<ISD::OutputArg, 32> &Outs = CLI.Outs;
  SmallVector<SDValue, 32> &OutVals = CLI.OutVals;
  SmallVector<ISD::InputArg, 32> &Ins = CLI.Ins;
  SDValue InChain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  bool &IsTailCall = CLI.IsTailCall;
  CallingConv::ID CallConv = CLI.CallConv;
  bool IsVarArg = CLI.IsVarArg;

  // Tile target does not yet support tail call optimization.
  IsTailCall = false;

  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  bool IsPIC = getTargetMachine().getRelocationModel() == Reloc::PIC_;
  TileFunctionInfo *TileFI = MF.getInfo<TileFunctionInfo>();

  // Analyze operands of the call, assigning locations to each operand.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), ArgLocs, *DAG.getContext());

  AnalyzeTileCallOperands(CCInfo, Outs);

  // Get a count of how many bytes are to be pushed on the stack.
  unsigned NextStackOffset = CCInfo.getNextStackOffset();

  // Chain is the output chain of the last Load/Store or CopyToReg node.
  // ByValChain is the output chain of the last Memcpy node created for
  // copying byval arguments to the stack.
  SDValue Chain, CallSeqStart, ByValChain;
  SDValue NextStackOffsetVal = DAG.getIntPtrConstant(NextStackOffset, true);
  Chain = CallSeqStart = DAG.getCALLSEQ_START(InChain, NextStackOffsetVal);

  unsigned MaxCallFrameSize = TileFI->getMaxCallFrameSize();

  SDValue StackPtr = DAG.getCopyFromReg(Chain, dl, Tile::SP, getPointerTy());

  if (MaxCallFrameSize < NextStackOffset)
    TileFI->setMaxCallFrameSize(NextStackOffset);

  SmallVector<std::pair<unsigned, SDValue>, TILEGX_AREG_NUM> RegsToPass;
  SmallVector<SDValue, 8> MemOpChains;

  // Walk the register/memloc assignments, inserting copies/loads.
  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    SDValue Arg = OutVals[i];
    CCValAssign &VA = ArgLocs[i];
    MVT ValVT = VA.getValVT(), LocVT = VA.getLocVT();
    ISD::ArgFlagsTy Flags = Outs[i].Flags;

    // ByVal Arg.
    if (Flags.isByVal()) {
      assert(Flags.getByValSize() &&
             "ByVal args of size 0 should have been ignored by front-end.");
      passByValArg(Chain, dl, RegsToPass, MemOpChains, StackPtr, MFI, DAG, Arg,
                   VA, Flags);
      continue;
    }

    // Promote the value if needed.
    switch (VA.getLocInfo()) {
    default:
      llvm_unreachable("Unknown loc info!");
    case CCValAssign::Full:
      if (!VA.isRegLoc())
        break;
      if ((ValVT == MVT::f32 && LocVT == MVT::i32) ||
          (ValVT == MVT::f64 && LocVT == MVT::i64))
        Arg = DAG.getNode(ISD::BITCAST, dl, LocVT, Arg);
      else if (ValVT == MVT::f64 && LocVT == MVT::i32)
        llvm_unreachable("No support for this yet!\n");
      break;
    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, dl, LocVT, Arg);
      break;
    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, dl, LocVT, Arg);
      break;
    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, dl, LocVT, Arg);
      break;
    }

    // Arguments that can be passed on register must be kept at
    // RegsToPass vector.
    if (VA.isRegLoc()) {
      RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
      continue;
    }

    // Register can't get to this point.
    assert(VA.isMemLoc());

    // emit ISD::STORE whichs stores the parameter value to a stack Location.
    SDValue PtrOff = DAG.getNode(ISD::ADD, dl, getPointerTy(), StackPtr,
                                 DAG.getIntPtrConstant(VA.getLocMemOffset()));
    MemOpChains.push_back(DAG.getStore(Chain, dl, Arg, PtrOff,
                                       MachinePointerInfo(), false, false, 0));
  }

  // Transform all store nodes into one single node because all store
  // nodes are independent of each other.
  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, &MemOpChains[0],
                        MemOpChains.size());

  if (Callee->getOpcode() == ISD::GlobalTLSAddress) {
    GlobalAddressSDNode *G = cast<GlobalAddressSDNode>(Callee);
    TLSModel::Model Model = getTargetMachine().getTLSModel(G->getGlobal());
    if (Model == TLSModel::GeneralDynamic || Model == TLSModel::LocalDynamic)
      Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, getPointerTy(), 0,
                                          TileII::MO_TLS_GD_CALL);
    else
      llvm_unreachable("only GD/LD will call __tls_get_addr");
  } else if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    if (IsPIC && !G->getGlobal()->hasInternalLinkage())
      Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, getPointerTy(), 0,
                                          TileII::MO_PLT_CALL);
    else
      Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, getPointerTy(), 0,
                                          TileII::MO_NO_FLAG);
  } else if (ExternalSymbolSDNode *S = dyn_cast<ExternalSymbolSDNode>(Callee)) {
    if (IsPIC)
      Callee = DAG.getTargetExternalSymbol(S->getSymbol(), getPointerTy(),
                                           TileII::MO_PLT_CALL);
    else
      Callee = DAG.getTargetExternalSymbol(S->getSymbol(), getPointerTy(),
                                           TileII::MO_NO_FLAG);
  }

  SDValue InFlag;

  // Build a sequence of copy-to-reg nodes chained together with token
  // chain and flag operands which copy the outgoing args into registers.
  // The InFlag in necessary since all emitted instructions must be
  // stuck together.
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i) {
    Chain = DAG.getCopyToReg(Chain, dl, RegsToPass[i].first,
                             RegsToPass[i].second, InFlag);
    InFlag = Chain.getValue(1);
  }

  // TileJmpLink = #chain, #target_address, #opt_in_flags...
  //             = Chain, Callee, Reg#1, Reg#2, ...
  //
  // Returns a chain & a flag for retval copy to use.
  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  // Add argument registers to the end of the list so that they are
  // known live into the call.
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i)
    Ops.push_back(DAG.getRegister(RegsToPass[i].first,
                                  RegsToPass[i].second.getValueType()));

  // Add a register mask operand representing the call-preserved registers.
  const TargetRegisterInfo *TRI = getTargetMachine().getRegisterInfo();
  const uint32_t *Mask = TRI->getCallPreservedMask(CallConv);
  assert(Mask && "Missing call preserved mask for calling convention");
  Ops.push_back(DAG.getRegisterMask(Mask));

  if (InFlag.getNode())
    Ops.push_back(InFlag);

  Chain = DAG.getNode(TileISD::JmpLink, dl, NodeTys, &Ops[0], Ops.size());
  InFlag = Chain.getValue(1);

  // Create the CALLSEQ_END node.
  Chain =
      DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(NextStackOffset, true),
                         DAG.getIntPtrConstant(0, true), InFlag);
  InFlag = Chain.getValue(1);

  // Handle result values, copying them out of physregs into vregs that we
  // return.
  return LowerCallResult(Chain, InFlag, CallConv, IsVarArg, Ins, dl, DAG,
                         InVals);
}

// Lower the result values of a call into the appropriate copies
// out of appropriate physical registers.
SDValue TileTargetLowering::LowerCallResult(
    SDValue Chain, SDValue InFlag, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, DebugLoc dl, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> &InVals) const {
  // Assign locations to each value returned by this call.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), RVLocs, *DAG.getContext());

  CCInfo.AnalyzeCallResult(Ins, RetCC_Tile);

  // Copy all of the result registers out of their specified physreg.
  for (unsigned i = 0, e = RVLocs.size(); i != e; ++i) {
    Chain = DAG.getCopyFromReg(Chain, dl, RVLocs[i].getLocReg(),
                               RVLocs[i].getValVT(), InFlag).getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

// Create frame object on stack and copy registers used for byval passing to it.
static unsigned CopyTileByValRegs(
    MachineFunction &MF, SDValue Chain, DebugLoc dl,
    std::vector<SDValue> &OutChains, SelectionDAG &DAG, const CCValAssign &VA,
    const ISD::ArgFlagsTy &Flags, MachineFrameInfo *MFI, bool IsRegLoc,
    SmallVectorImpl<SDValue> &InVals, TileFunctionInfo *TileFI, EVT PtrTy,
    const Argument *FuncArg) {
  const uint16_t *Reg = TileIntRegs + TILEGX_AREG_NUM;
  int FOOffset;
  int ByRegSize = 0;
  int ByMemSize = 0;
  unsigned Align = std::max(Flags.getByValAlign(), (unsigned) 8);
  int ByValSize = RoundUpToAlignment(Flags.getByValSize(), Align);

  if (IsRegLoc) {
    Reg = std::find(TileIntRegs, TileIntRegs + TILEGX_AREG_NUM, VA.getLocReg());
    // For Tilegx, the stack layout looks like:
    //
    // -----
    //
    // Out going
    // -----
    //
    // 16bytes reserved
    // -----
    //
    //
    // ----- <- FOOffset
    FOOffset = -ByValSize;
    ByRegSize = (TILEGX_AREG_NUM - (Reg - TileIntRegs)) * 8;
    ByMemSize = ByValSize - ByRegSize;
  } else
    FOOffset = VA.getLocMemOffset();

  // Create frame object.
  unsigned LastFI = MFI->CreateFixedObject(ByValSize, FOOffset, true);
  SDValue FIN = DAG.getFrameIndex(LastFI, PtrTy);
  InVals.push_back(FIN);

  // Copy arg registers.
  for (int I = 0;(Reg != TileIntRegs + TILEGX_AREG_NUM) && (I * 8) < ByValSize;
       ++Reg, ++I) {
    unsigned VReg = AddLiveIn(MF, *Reg, &Tile::CPURegsRegClass);
    SDValue StorePtr =
        DAG.getNode(ISD::ADD, dl, PtrTy, FIN, DAG.getConstant(I * 8, PtrTy));
    SDValue Store =
        DAG.getStore(Chain, dl, DAG.getRegister(VReg, MVT::i64), StorePtr,
                     MachinePointerInfo(FuncArg, I * 8), false, false, 0);
    OutChains.push_back(Store);
  }

  if (ByMemSize) {
    SDValue Dst = DAG.getNode(ISD::ADD, dl, PtrTy, FIN,
                              DAG.getConstant(ByRegSize, PtrTy));

    SDValue Src =
        DAG.getNode(ISD::ADD, dl, PtrTy, FIN,
                    DAG.getConstant(ByValSize + TILEGX_BZONE_SIZE, PtrTy));

    Chain =
        DAG.getMemcpy(Chain, dl, Dst, Src, DAG.getConstant(ByMemSize, PtrTy), 8,
                      /*isVolatile=*/ false, /*AlwaysInline=*/ false,
                      MachinePointerInfo(0), MachinePointerInfo(0));

    OutChains.push_back(Chain);
  }

  return LastFI;
}

// Transform physical registers into virtual registers and generate load
// operations for arguments places on the stack.
SDValue TileTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, DebugLoc dl, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  TileFunctionInfo *TileFI = MF.getInfo<TileFunctionInfo>();

  TileFI->setVarArgsFrameIndex(0);

  // Used with vargs to acumulate store chains.
  std::vector<SDValue> OutChains;

  // Assign locations to all of the incoming arguments.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), ArgLocs, *DAG.getContext());

  CCInfo.AnalyzeFormalArguments(Ins, CC_Tile);

  Function::const_arg_iterator FuncArg =
      DAG.getMachineFunction().getFunction()->arg_begin();
  int LastFI = 0;

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i, ++FuncArg) {
    CCValAssign &VA = ArgLocs[i];
    EVT ValVT = VA.getValVT();
    ISD::ArgFlagsTy Flags = Ins[i].Flags;
    bool IsRegLoc = VA.isRegLoc();

    if (Flags.isByVal()) {
      assert(Flags.getByValSize() &&
             "ByVal args of size 0 should have been ignored by front-end.");
      LastFI = CopyTileByValRegs(MF, Chain, dl, OutChains, DAG, VA, Flags, MFI,
                                 IsRegLoc, InVals, TileFI, getPointerTy(),
                                 &*FuncArg);
      continue;
    }

    // Arguments stored on registers.
    if (IsRegLoc) {
      EVT RegVT = VA.getLocVT();
      unsigned ArgReg = VA.getLocReg();
      const TargetRegisterClass *RC;

      if (RegVT == MVT::i32 || RegVT == MVT::f32)
        RC = &Tile::CPU32RegsRegClass;
      else
        RC = &Tile::CPURegsRegClass;

      // Transform the arguments stored on physical registers into virtual ones.
      unsigned Reg = AddLiveIn(DAG.getMachineFunction(), ArgReg, RC);
      SDValue ArgValue = DAG.getCopyFromReg(Chain, dl, Reg, RegVT);

      // If this is an 8 or 16-bit value, it has been passed promoted
      // to 32 bits.  Insert an assert[sz]ext to capture this, then
      // truncate to the right size.
      if (VA.getLocInfo() != CCValAssign::Full) {
        unsigned Opcode = 0;
        if (VA.getLocInfo() == CCValAssign::SExt)
          Opcode = ISD::AssertSext;
        else if (VA.getLocInfo() == CCValAssign::ZExt)
          Opcode = ISD::AssertZext;
        if (Opcode)
          ArgValue =
              DAG.getNode(Opcode, dl, RegVT, ArgValue, DAG.getValueType(ValVT));
        ArgValue = DAG.getNode(ISD::TRUNCATE, dl, ValVT, ArgValue);
      }

      // Handle floating point arguments passed in integer registers.
      if ((RegVT == MVT::i32 && ValVT == MVT::f32) ||
          (RegVT == MVT::i64 && ValVT == MVT::f64))
        ArgValue = DAG.getNode(ISD::BITCAST, dl, ValVT, ArgValue);

      InVals.push_back(ArgValue);
    } else { // VA.isRegLoc()

      // Sanity check.
      assert(VA.isMemLoc());

      // The stack pointer offset is relative to the caller stack frame.
      LastFI = MFI->CreateFixedObject(ValVT.getSizeInBits() / 8,
                                      VA.getLocMemOffset(), true);

      // Create load nodes to retrieve arguments from the stack.
      SDValue FIN = DAG.getFrameIndex(LastFI, getPointerTy());
      InVals.push_back(DAG.getLoad(ValVT, dl, Chain, FIN,
                                   MachinePointerInfo::getFixedStack(LastFI),
                                   false, false, false, 0));
    }
  }

  // The Tile ABIs for returning structs by value requires that we copy
  // the sret argument into r0 for the return. Save the argument into
  // a virtual register so that we can access it from the return points.
  if (DAG.getMachineFunction().getFunction()->hasStructRetAttr()) {
    unsigned Reg = TileFI->getSRetReturnReg();
    if (!Reg) {
      Reg = MF.getRegInfo().createVirtualRegister(getRegClassFor(MVT::i64));
      TileFI->setSRetReturnReg(Reg);
    }
    SDValue Copy = DAG.getCopyToReg(DAG.getEntryNode(), dl, Reg, InVals[0]);
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, Copy, Chain);
  }

  if (IsVarArg) {
    unsigned NumOfRegs = TILEGX_AREG_NUM;
    const uint16_t *ArgRegs = TileIntRegs;
    unsigned Idx = CCInfo.getFirstUnallocated(ArgRegs, NumOfRegs);
    int FirstRegSlotOffset = -80; // Offset of r0's slot.
    const TargetRegisterClass *RC = &Tile::CPURegsRegClass;
    unsigned RegSize = RC->getSize();
    int RegSlotOffset = FirstRegSlotOffset + Idx * RegSize;

    // Offset of the first variable argument from stack pointer.
    int FirstVaArgOffset;

    if (Idx == NumOfRegs) {
      FirstVaArgOffset =
          (CCInfo.getNextStackOffset() + RegSize - 1) / RegSize * RegSize;
    } else
      FirstVaArgOffset = RegSlotOffset;

    // Record the frame index of the first variable argument
    // which is a value necessary to VASTART.
    LastFI = MFI->CreateFixedObject(RegSize, FirstVaArgOffset, true);
    TileFI->setVarArgsFrameIndex(LastFI);

    // Copy the integer registers that have not been used for argument passing
    // to the argument register save area.
    for (int StackOffset = RegSlotOffset; Idx < NumOfRegs;
         ++Idx, StackOffset += RegSize) {
      unsigned Reg = AddLiveIn(DAG.getMachineFunction(), ArgRegs[Idx], RC);
      SDValue ArgValue =
          DAG.getCopyFromReg(Chain, dl, Reg, MVT::getIntegerVT(RegSize * 8));
      LastFI = MFI->CreateFixedObject(RegSize, StackOffset, true);
      SDValue PtrOff = DAG.getFrameIndex(LastFI, getPointerTy());
      OutChains.push_back(DAG.getStore(Chain, dl, ArgValue, PtrOff,
                                       MachinePointerInfo(), false, false, 0));
    }

  }

  // All stores are grouped in one node to allow the matching between
  // the size of Ins and InVals. This only happens when on varg functions.
  if (!OutChains.empty()) {
    OutChains.push_back(Chain);
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, &OutChains[0],
                        OutChains.size());
  }

  return Chain;
}

//===----------------------------------------------------------------------===//
//               Return Value Calling Convention Implementation
//===----------------------------------------------------------------------===//

SDValue TileTargetLowering::LowerReturn(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs,
    const SmallVectorImpl<SDValue> &OutVals, DebugLoc dl,
    SelectionDAG &DAG) const {

  SmallVector<CCValAssign, 16> RVLocs;

  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), RVLocs, *DAG.getContext());

  // Analize return values.
  CCInfo.AnalyzeReturn(Outs, RetCC_Tile);

  SDValue Flag;
  SmallVector<SDValue, 12> RetOps(1, Chain);
  RetOps.push_back(SDValue());

  // Copy the result values into the output registers.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    Chain = DAG.getCopyToReg(Chain, dl, VA.getLocReg(), OutVals[i], Flag);

    // Guarantee that all emitted copies are stuck together with flags.
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  // The Tile ABIs for returning structs by value requires that we copy
  // the sret argument into r0 for the return. We saved the argument into
  // a virtual register in the entry block, so now we copy the value out
  // and into r0.
  if (DAG.getMachineFunction().getFunction()->hasStructRetAttr()) {
    MachineFunction &MF = DAG.getMachineFunction();
    TileFunctionInfo *TileFI = MF.getInfo<TileFunctionInfo>();
    unsigned Reg = TileFI->getSRetReturnReg();

    if (!Reg)
      llvm_unreachable("sret virtual register not created in the entry block");
    SDValue Val = DAG.getCopyFromReg(Chain, dl, Reg, getPointerTy());

    Chain = DAG.getCopyToReg(Chain, dl, Tile::R0, Val, Flag);
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(Tile::R0, getPointerTy()));
  }

  // Return on Tile is always a "jr $ra"
  RetOps[0] = Chain; // Update chain.
  RetOps[1] = DAG.getRegister(Tile::LR, MVT::i64);

  // Add the flag if we have it.
  if (Flag.getNode())
    RetOps.push_back(Flag);

  return DAG.getNode(TileISD::Ret, dl, MVT::Other, &RetOps[0], RetOps.size());
}

//===----------------------------------------------------------------------===//
//                           Tile Inline Assembly Support
//===----------------------------------------------------------------------===//

/// Return the type of constraint it is for this target.
TileTargetLowering::ConstraintType
TileTargetLowering::getConstraintType(const std::string &Constraint) const {
  // Tile specific constrainy
  // GCC config/tile/constraints.md
  //
  // 'd' : An address register.
  // 'y' : Equivalent to r; retained for
  //       backwards compatibility.
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    default:
      break;
    case 'd':
    case 'y':
      return C_RegisterClass;
    }
  }
  return TargetLowering::getConstraintType(Constraint);
}

// Examine constraint type and operand type and determine a weight value.
// This object must already have been set up with the operand type
// and the current alternative constraint selected.
TargetLowering::ConstraintWeight
TileTargetLowering::getSingleConstraintMatchWeight(
    AsmOperandInfo &info, const char *constraint) const {
  ConstraintWeight Weight = CW_Invalid;
  Value *CallOperandVal = info.CallOperandVal;
  // If we don't have a value, we can't do a match,
  // but allow it at the lowest weight.
  if (CallOperandVal == NULL)
    return CW_Default;
  Type *type = CallOperandVal->getType();
  // Look at the constraint type.
  switch (*constraint) {
  default:
    Weight = TargetLowering::getSingleConstraintMatchWeight(info, constraint);
    break;
  case 'd':
  case 'y':
    if (type->isIntegerTy())
      Weight = CW_Register;
    break;
  }
  return Weight;
}

// Given a register class constraint, like 'r', if this corresponds directly
// to an LLVM register class, return a register of 0 and the register class
// pointer.
std::pair<unsigned, const TargetRegisterClass *>
TileTargetLowering::getRegForInlineAsmConstraint(const std::string &Constraint,
                                                 EVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'd': // Address register.
    case 'y': // Same as 'r'. Exists for compatibility.
    case 'r':
      return std::make_pair(0U, &Tile::CPURegsRegClass);
    }
  }
  return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

unsigned TileTargetLowering::getJumpTableEncoding() const {
  return MachineJumpTableInfo::EK_Inline;
}

EVT TileTargetLowering::getSetCCResultType(EVT VT) const {
  if (!VT.isVector())
    return MVT::i32;
  return VT.changeVectorElementTypeToInteger();
}

bool
TileTargetLowering::isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const {
  // The Tile target isn't yet aware of offsets.
  return false;
}
