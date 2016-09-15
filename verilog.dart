
enum PortDirection {
  Input, Output, InOut
}
List<String> portDirectionNames = ["input", "output", "inout"];

class VerilogPort {
  String name;
  PortDirection direction;
  int width;
  VerilogPort(this.name, this.direction, [this.width=1]);
  String emitDeclaration() => "${portDirectionNames[direction.index]} $name";
}

class VerilogRegister {
  String name;
  int width;
  VerilogRegister(this.name, [this.width=1]);
  void emitDeclaration() {
    String widthspec = "";
    if (width > 1)
      widthspec = "[$width]";
    return "reg $widthspec $name;";
  }
}

class VerilogModule {
  var name;
  var ports;
  var signals;
  var registers;
  VerilogModule(this.name)
    : ports = [new VerilogPort("CLK", PortDirection.Input), new VerilogPort("RST_N", PortDirection.Input)]
    , signals = []
    , registers = [] {}
  
  void emitVerilog() {
    print("module $name (");
    print("    " + ports.map((p) => p.emitDeclaration()).join(",\n    "));
    print("    );");
    print(registers.map((r) => "    ${r.emitDeclaration()}").join("\n"));
    for (var signaliter = signals.iterator; signaliter.moveNext();)
      signaliter.current.emitDeclaration();
    print("endmodule");
  }
}
