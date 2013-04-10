//===-- TileInstrFormats.td - Tile Instruction Formats -----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


//*********************************
//            Tilegx
//
//*********************************
// Instruction Encoding Format.
class TileFormat<bits<4> val> {
  bits<4> Value = val;
}

def   FrmRRR     : TileFormat<0>;
def   FrmImm8    : TileFormat<1>;
def   FrmMTImm14 : TileFormat<2>;
def   FrmMFImm14 : TileFormat<3>;
def   FrmImm16   : TileFormat<4>;
def   FrmUnary   : TileFormat<5>;
def   FrmShift   : TileFormat<6>;
def   FrmBr      : TileFormat<7>;
def   FrmJmp     : TileFormat<8>;
def   FrmMM      : TileFormat<9>;
def   FrmLS      : TileFormat<10>;
def   FrmPseudo  : TileFormat<11>;

// Instrauction Catalog.
class TileValidSlot<bits<4> val> {
      bits<4> Value = val;
}

def  S_NONE    : TileValidSlot<0>;
def  S_X0      : TileValidSlot<1>;
def  S_X1      : TileValidSlot<2>;
def  S_X0_X1   : TileValidSlot<3>;
def  S_X0_Y0   : TileValidSlot<4>;
def  S_X1_Y1   : TileValidSlot<5>;
def  S_X1_Y2   : TileValidSlot<6>;
def  S_X0_X1_Y0_Y1   : TileValidSlot<7>;

// Generic TIlegx Format.
class TileInst< dag outs,
       		dag ins,
       		string asmstr,
       		list<dag> pattern,
       		InstrItinClass itin,
       		TileFormat f,
                TileValidSlot s>
       		: Instruction {
	string Op;
	bits<64> Inst;	

	let Namespace = "Tile";

	let OutOperandList = outs;
	let InOperandList = ins;	
	let AsmString = asmstr;
	let Pattern = pattern;
	let Itinerary = itin;

        TileValidSlot InstSlot = s;
        let TSFlags{3-0} = s.Value;

        bits<1> isSoloInst = 0;
        let TSFlags{4} = isSoloInst;

	TileFormat Form = f;	
        let TSFlags{8-5} = f.Value;
}

// *****************************************************
//          Below are solo instruction encode format.
// *****************************************************

// A solo instruction issued from X0 slot, packed with FNOP.
// {
// INST_fmtRRR
// FNOP
// }
class TileInstX0RRR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rsa;
  bits<6>  rsb;
  bits<6>  rd;

  // Mark the bundle as X mode.
  let Inst{63-62} = 0x0;
  // Encode the X1 slot with FNOP.
  let Inst{61-31} = 0x50d46000;
  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = rsb;
  let Inst{11-6} = rsa;
  let Inst{5-0} = rd;
}
 
class TileInstX0Unary<bits<3> op, bits<10> sub_op, bits<6> u_op,
                      dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;

  let Inst{63-62} = 0x0;
  let Inst{61-31} = 0x50d46000;
  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = u_op;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

// A solo instruction issued from X1 slot, packed with FNOP.
// {
// FNOP
// INST_fmtRRR
// }
class TileInstX1RRR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rsa;
  bits<6>  rsb;
  bits<6>  rd;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = rsb;
  let Inst{42-37} = rsa;
  let Inst{36-31} = rd;
  // Encode the X0 slot with FNOP.
  let Inst{30-0} = 0x51483000;
}
                     
class TileInstX1RRZ<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = 0x3F;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileInstX1RZR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = rs;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileInstX1Shift<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<6>  sht;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = sht;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileInstX1Imm8<bits<3> op, bits<8> sub_op, dag outs, dag ins,
                     string asmstr, list<dag> pattern, InstrItinClass itin,
                     TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-51} = sub_op;
  let Inst{50-43} = imm8;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileInstX1Imm16<bits<3> op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<16> imm16;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-43} = imm16;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileInstX1Jump<bits<3> op, bits<1> j_op, dag outs, dag ins,
                     string asmstr, list<dag> pattern, InstrItinClass itin,
                     TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<27> j_target;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-58} = j_op;
  let Inst{57-31} = j_target;
  let Inst{30-0} = 0x51483000;
}

class TileSTOREX1<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                string asmstr, list<dag> pattern, InstrItinClass itin,
                TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  addr;
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = rs;
  let Inst{42-37} = addr;
  let Inst{36-31} = 0x0;
  let Inst{30-0} = 0x51483000;
}

class TileSTOREY2<bits<2> op, dag outs, dag ins,
                  string asmstr, list<dag> pattern, InstrItinClass itin,
                  TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  addr;
  // mark the bundle as Y Store mode
  let Inst{63-62} = 0x3;
  let Inst{61-58} = 0x7;
  let Inst{57} = op{1};
  let Inst{56-51} = rs;
  let Inst{50-31} = 0xC8000;
  let Inst{30-27} = 0x6;
  let Inst{26} = op{0};
  let Inst{25-20} = addr;
  let Inst{19-0} = 0xC3000;
}

class TileLOADX1<bits<3> op, bits<10> sub_op, bits<6> u_op, dag outs, dag ins,
                 string asmstr, list<dag> pattern, InstrItinClass itin,
                 TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  addr;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = addr;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileLOADY2<bits<2> mode, bits<2> op, dag outs, dag ins,
                 string asmstr, list<dag> pattern, InstrItinClass itin,
                 TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  addr;
  let Inst{63-62} = mode;
  let Inst{61-58} = 0x7;
  let Inst{57} = op{1};
  let Inst{56-51} = rd;
  let Inst{50-31} = 0xC8000;
  let Inst{30-27} = 0x6;
  let Inst{26} = op{0};
  let Inst{25-20} = addr;
  let Inst{19-0} = 0xC3000;
}

class TileLNKX1<bits<3> op, bits<10> sub_op, bits<6> u_op, dag outs, dag ins,
                string asmstr, list<dag> pattern, InstrItinClass itin,
                 TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = 0x0;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileJRX1<bits<3> op, bits<10> sub_op, bits<6> u_op, dag outs, dag ins,
               string asmstr, list<dag> pattern, InstrItinClass itin,
               TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = rs;
  let Inst{36-31} = 0x0;
  let Inst{30-0} = 0x51483000;
}

class TileMFX1<bits<3> op, bits<10> sub_op, bits<6> u_op, dag outs, dag ins,
                string asmstr, list<dag> pattern, InstrItinClass itin,
                 TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = 0x0;
  let Inst{36-31} = 0x0;
  let Inst{30-0} = 0x51483000;
}

class TileMOVEIX1<bits<3> op, bits<8> sub_op, dag outs, dag ins,
                  string asmstr, list<dag> pattern, InstrItinClass itin,
                  TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-51} = sub_op;
  let Inst{50-43} = imm8;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileMOVELIX1<bits<3> op, dag outs, dag ins,
                   string asmstr, list<dag> pattern, InstrItinClass itin,
                   TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<16> imm16;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-43} = imm16;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;
  let Inst{30-0} = 0x51483000;
}

class TileInstX1Branch<bits<3> op, bits<5> btype, dag outs, dag ins,
                       string asmstr, list<dag> pattern, InstrItinClass itin,
                       TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<17> br_target;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-54} = btype;
  let Inst{53-43} = br_target{16-6};
  let Inst{42-37} = rs;
  let Inst{36-31} = br_target{5-0};
  let Inst{30-0} = 0x51483000;
}

// *****************************************************
//          Below are instruction bundle encode format.
// *****************************************************

class TileBundleX0RRR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rsa;
  bits<6>  rsb;
  bits<6>  rd;

  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = rsb;
  let Inst{11-6} = rsa;
  let Inst{5-0} = rd;
}

class TileBundleX1RRR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rsa;
  bits<6>  rsb;
  bits<6>  rd;

  // Mark the bundle as X mode
  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = rsb;
  let Inst{42-37} = rsa;
  let Inst{36-31} = rd;
}

class TileBundleY0RRR<bits<4> op, bits<2> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rsa;
  bits<6>  rsb;
  bits<6>  rd;

  let Inst{30-27} = op;
  let Inst{19-18} = sub_op;
  let Inst{17-12} = rsb;
  let Inst{11-6} = rsa;
  let Inst{5-0} = rd;
}

class TileBundleY1RRR<bits<4> op, bits<2> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rsa;
  bits<6>  rsb;
  bits<6>  rd;

  let Inst{61-58} = op;
  let Inst{50-49} = sub_op;
  let Inst{48-43} = rsb;
  let Inst{42-37} = rsa;
  let Inst{36-31} = rd;
}

class TileBundleX0RZR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = rs;
  let Inst{11-6} = 0x3F;
  let Inst{5-0} = rd;
}

class TileBundleX1RZR<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = rs;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;
}

class TileBundleX0RRZ<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = 0x3F;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleX1RRZ<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = 0x3F;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleY0RRZ<bits<4> op, bits<2> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{30-27} = op;
  let Inst{19-18} = sub_op;
  let Inst{17-12} = 0x3F;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleY1RRZ<bits<4> op, bits<2> sub_op, dag outs, dag ins,
                      string asmstr, list<dag> pattern, InstrItinClass itin,
                      TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  rs;

  let Inst{61-58} = op;
  let Inst{50-49} = sub_op;
  let Inst{48-43} = 0x3F;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleX0Imm8<bits<3> op, bits<8> sub_op, dag outs, dag ins,
                       string asmstr, list<dag> pattern, InstrItinClass itin,
                       TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{30-28} = op;
  let Inst{27-20} = sub_op;
  let Inst{19-12} = imm8;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleX1Imm8<bits<3> op, bits<8> sub_op, dag outs, dag ins,
                       string asmstr, list<dag> pattern, InstrItinClass itin,
                       TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-51} = sub_op;
  let Inst{50-43} = imm8;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleY0Imm8<bits<4> op, dag outs, dag ins,
                       string asmstr, list<dag> pattern, InstrItinClass itin,
                       TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{30-27} = op;
  let Inst{19-12} = imm8;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleY1Imm8<bits<4> op, dag outs, dag ins,
                       string asmstr, list<dag> pattern, InstrItinClass itin,
                       TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{61-58} = op;
  let Inst{50-43} = imm8;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleX0Imm16<bits<3> op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<16> imm16;

  let Inst{30-28} = op;
  let Inst{27-12} = imm16;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleX1Imm16<bits<3> op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<16> imm16;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-43} = imm16;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleX0Shift<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<6>  sht;

  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = sht;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleX1Shift<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<6>  sht;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = sht;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleY0Shift<bits<4> op, bits<2> sub_op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<6>  sht;

  let Inst{30-27} = op;
  let Inst{19-18} = sub_op;
  let Inst{17-12} = sht;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleY1Shift<bits<4> op, bits<2> sub_op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;
  bits<6>  sht;

  let Inst{61-58} = op;
  let Inst{50-49} = sub_op;
  let Inst{48-43} = sht;
  let Inst{42-37} = rs;
  let Inst{36-31} = rd;
}

class TileBundleX0MOVEI<bits<3> op, bits<8> sub_op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{30-28} = op;
  let Inst{27-20} = sub_op;
  let Inst{19-12} = imm8;
  let Inst{11-6} = 0x3F;
  let Inst{5-0} = rd;
}

class TileBundleX1MOVEI<bits<3> op, bits<8> sub_op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-51} = sub_op;
  let Inst{50-43} = imm8;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;
}

class TileBundleY0MOVEI<bits<4> op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{30-27} = op;
  let Inst{19-12} = imm8;
  let Inst{11-6} = 0x3F;
  let Inst{5-0} = rd;
}

class TileBundleY1MOVEI<bits<4> op, dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<8>  imm8;

  let Inst{61-58} = op;
  let Inst{50-43} = imm8;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;

}

class TileBundleX0MOVELI<bits<3> op, dag outs, dag ins,
                         string asmstr, list<dag> pattern, InstrItinClass itin,
                         TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<16> imm16;

  let Inst{30-28} = op;
  let Inst{27-12} = imm16;
  let Inst{11-6} = 0x3F;
  let Inst{5-0} = rd;
}

class TileBundleX1MOVELI<bits<3> op, dag outs, dag ins,
                         string asmstr, list<dag> pattern, InstrItinClass itin,
                         TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<16> imm16;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-43} = imm16;
  let Inst{42-37} = 0x3F;
  let Inst{36-31} = rd;
}

class TileBundleX1Branch<bits<3> op, bits<5> btype, dag outs, dag ins,
                         string asmstr, list<dag> pattern, InstrItinClass itin,
                         TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<17> br_target;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-54} = btype;
  let Inst{53-43} = br_target{16-6};
  let Inst{42-37} = rs;
  let Inst{36-31} = br_target{5-0};
}

class TileBundleX0Unary<bits<3> op, bits<10> sub_op, bits<6> u_op,
                        dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;

  let Inst{30-28} = op;
  let Inst{27-18} = sub_op;
  let Inst{17-12} = u_op;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleY0Unary<bits<4> op, bits<2> sub_op, bits<6> u_op,
                        dag outs, dag ins,
                        string asmstr, list<dag> pattern, InstrItinClass itin,
                        TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  rd;

  let Inst{30-27} = op;
  let Inst{19-18} = sub_op;
  let Inst{17-12} = u_op;
  let Inst{11-6} = rs;
  let Inst{5-0} = rd;
}

class TileBundleX1L<bits<3> op, bits<10> sub_op, bits<6> u_op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  addr;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = addr;
  let Inst{36-31} = rd;
}

class TileBundleX1S<bits<3> op, bits<10> sub_op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  addr;
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = rs;
  let Inst{42-37} = addr;
  let Inst{36-31} = 0x0;
}

class TileBundleY2L<bits<2> mode, bits<2> op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;
  bits<6>  addr;
  // mark the bundle as Y Load mode
  let Inst{63-62} = mode;

  let Inst{57} = op{1};
  let Inst{56-51} = rd;
  let Inst{26} = op{0};
  let Inst{25-20} = addr;
}

class TileBundleY2S<bits<2> op, dag outs, dag ins,
                    string asmstr, list<dag> pattern, InstrItinClass itin,
                    TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;
  bits<6>  addr;
  // mark the bundle as Y Store mode
  let Inst{63-62} = 0x3;

  let Inst{57} = op{1};
  let Inst{56-51} = rs;
  let Inst{26} = op{0};
  let Inst{25-20} = addr;

}

class TileBundleX1LNK<bits<3> op, bits<10> sub_op, bits<6> u_op,
                      dag outs, dag ins, string asmstr, list<dag> pattern,
                      InstrItinClass itin, TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rd;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = 0x0;
  let Inst{36-31} = rd;
}

class TileBundleX1MF<bits<3> op, bits<10> sub_op, bits<6> u_op,
                     dag outs, dag ins, string asmstr, list<dag> pattern,
                    InstrItinClass itin, TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = 0x0;
  let Inst{36-31} = 0x0;
}

class TileBundleX1Jump<bits<3> op, bits<1> j_op, dag outs, dag ins,
                       string asmstr, list<dag> pattern, InstrItinClass itin,
                       TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<27> j_target;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-58} = j_op;
  let Inst{57-31} = j_target;
}

class TileBundleX1JR<bits<3> op, bits<10> sub_op, bits<6> u_op,
                     dag outs, dag ins, string asmstr, list<dag> pattern,
                     InstrItinClass itin, TileFormat f, TileValidSlot s>
      : TileInst<outs, ins, asmstr, pattern, itin, f, s> {
  bits<6>  rs;

  let Inst{63-62} = 0x0;
  let Inst{61-59} = op;
  let Inst{58-49} = sub_op;
  let Inst{48-43} = u_op;
  let Inst{42-37} = rs;
  let Inst{36-31} = 0x0;
}

class TilePseudo<dag outs,
      		 dag ins,
		 string asmstr,
		 list<dag> pattern,
                 InstrItinClass itin>
	:	 TileInst<outs,
		 ins,
		 asmstr,
		 pattern,
		 itin,
		 FrmPseudo,
                 S_NONE> {
	let isCodeGenOnly = 1;
	let isPseudo = 1;
} 
