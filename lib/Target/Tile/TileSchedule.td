//===-- TileSchedule.td - Tile Scheduling Definitions ------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

// we actually only have 3 physical function units:
// X0 occupy P0
// X1 occupy P1 & P2
// Y0 occupy P0
// Y1 occupy P1
// Y2 occupy P2

def P0 : FuncUnit;
def P1 : FuncUnit;
def P2 : FuncUnit;

// Itinerary classes.

def IIC_ALU    : InstrItinClass;
def IIC_CMP    : InstrItinClass;
def IIC_BIT    : InstrItinClass;
def IIC_BIT_P0    : InstrItinClass;
def IIC_CTL    : InstrItinClass;
def IIC_CTL_P1 : InstrItinClass;
def IIC_FLOAT  : InstrItinClass;
def IIC_LOGIC  : InstrItinClass;
def IIC_LOGIC_P0  : InstrItinClass;
def IIC_MM     : InstrItinClass;
def IIC_MMA    : InstrItinClass;
def IIC_MUL    : InstrItinClass;
def IIC_SIMD   : InstrItinClass;
def IIC_PSEUDO_P1 : InstrItinClass;
def IIC_PSEUDO_ALL: InstrItinClass;

// Itineraries.

def TileItineraries : ProcessorItineraries<[P0, P1, P2], [], [
  InstrItinData<IIC_ALU,    [InstrStage<1, [P0, P1]>]>,
  InstrItinData<IIC_CMP,    [InstrStage<1, [P0, P1]>]>,
  InstrItinData<IIC_BIT,    [InstrStage<1, [P0, P1]>]>,
  InstrItinData<IIC_BIT_P0,    [InstrStage<1, [P0]>]>,
  InstrItinData<IIC_CTL,    [InstrStage<1, [P2]>]>,
  InstrItinData<IIC_CTL_P1, [InstrStage<1, [P1]>]>,
  InstrItinData<IIC_FLOAT,  [InstrStage<1, [P0]>]>,
  InstrItinData<IIC_LOGIC,  [InstrStage<1, [P0, P1]>]>,
  InstrItinData<IIC_LOGIC_P0,  [InstrStage<1, [P0]>]>,
  InstrItinData<IIC_MM,     [InstrStage<1, [P2]>]>,
  InstrItinData<IIC_MMA,    [InstrStage<1, [P1]>]>,
  InstrItinData<IIC_MUL,    [InstrStage<1, [P0]>]>,
  InstrItinData<IIC_SIMD,   [InstrStage<1, [P0, P1]>]>,
  InstrItinData<IIC_PSEUDO_P1, [InstrStage<1, [P1]>]>,
  InstrItinData<IIC_PSEUDO_ALL,[InstrStage<1, [P0, P1, P2]>]>
  ]>;

// Processor itineraries.
def TileModel : SchedMachineModel {
  // Max issue per cycle == bundle width.
  let IssueWidth = 3;
  let Itineraries = TileItineraries;
}

