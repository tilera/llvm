//===------ utils/obj2yaml.cpp - obj2yaml conversion tool -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "obj2yaml.h"
#include "llvm/ADT/OwningPtr.h"
#include "llvm/Object/Archive.h"
#include "llvm/Object/COFF.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"

using namespace llvm;

namespace yaml {  // generic yaml-writing specific routines

unsigned char printable(unsigned char Ch) {
  return Ch >= ' ' && Ch <= '~' ? Ch : '.';
}

raw_ostream &writeHexStream(raw_ostream &Out, const ArrayRef<uint8_t> arr) {
  const char *hex = "0123456789ABCDEF";
  Out << " !hex \"";

  typedef ArrayRef<uint8_t>::const_iterator iter_t;
  const iter_t end = arr.end();
  for (iter_t iter = arr.begin(); iter != end; ++iter)
    Out << hex[(*iter >> 4) & 0x0F] << hex[(*iter & 0x0F)];

  Out << "\" # |";
  for (iter_t iter = arr.begin(); iter != end; ++iter)
    Out << printable(*iter);
  Out << "|\n";

  return Out;
}

raw_ostream &writeHexNumber(raw_ostream &Out, unsigned long long N) {
  if (N >= 10)
    Out << "0x";
  Out.write_hex(N);
  return Out;
}

} // end namespace yaml

namespace {
enum ObjectFileType {
  coff
};
}

cl::opt<ObjectFileType> InputFormat(
    cl::desc("Choose input format"),
    cl::values(clEnumVal(coff, "process COFF object files"), clEnumValEnd));

cl::opt<std::string> InputFilename(cl::Positional, cl::desc("<input file>"),
                                   cl::init("-"));

int main(int argc, char *argv[]) {
  cl::ParseCommandLineOptions(argc, argv);
  sys::PrintStackTraceOnErrorSignal();
  PrettyStackTraceProgram X(argc, argv);
  llvm_shutdown_obj Y; // Call llvm_shutdown() on exit.

  // Process the input file
  OwningPtr<MemoryBuffer> buf;

  // TODO: If this is an archive, then burst it and dump each entry
  if (error_code ec = MemoryBuffer::getFileOrSTDIN(InputFilename, buf)) {
    errs() << "Error: '" << ec.message() << "' opening file '" << InputFilename
           << "'\n";
  } else {
    ec = coff2yaml(outs(), buf.take());
    if (ec)
      errs() << "Error: " << ec.message() << " dumping COFF file\n";
  }

  return 0;
}
