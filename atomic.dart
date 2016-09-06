import "dart:mirrors";

var themodule;
typedef bool Guard();
typedef void Body();

class Rule {
  var name;
  Guard guard;
  Body body;
  Rule(this.name, this.guard, this.body) {}
}

class guard {
  final Guard g;
  const guard(this.g);
}

class GuardedMethod {
    final method;
    final Guard guard;
    GuardedMethod(this.method, [this.guard = (() => true)]);
}

class Module {
  var name;
  var idle = true;
  var finished = false;
  static list<Module> modules = [];
  static list<Rule> rules = [];
  static list<Register> registers = [];

  Module(this.name) {
    idle = false;
    modules.add(this);
  }

  void addRule(name, Guard guard, Body body) {
    rules.add(new Rule(name, guard, body));
    var length = rules.length;
    print("addRule $name, now $length rules");
  }

  void finish() {
    finished = true;
  }

  void step() {
    var length = rules.length;
    print("Number of rules: $length");
    for (var iter = rules.iterator; iter.moveNext();) {
      var rule = iter.current;
      var name = rule.name;
      print("rule: $name");
      if (rule.guard()) {
        print("rule $name ready");
        idle = false;
        rule.body();
      }
    }
    if (!idle)
      for (var iter = registers.iterator; iter.moveNext();) {
        Reg reg = iter.current;
        reg.update();
      }
  }

  static void describeModules() {
    for (var moditer = modules.iterator; moditer.moveNext();) {
      var module = moditer.current;
      var moduleMirror = reflect(module);
      print("moduleMirror $moduleMirror");
      print("moduleMirror.type ${moduleMirror.type}");
      var declarations = moduleMirror.type.declarations;
      for (var iter = declarations.keys.iterator; iter.moveNext();) {
        var declMirror = declarations[iter.current];
        print("declMirror $declMirror");
        var metadata = declMirror.metadata;
        for (var miter = metadata.iterator; miter.moveNext();) {
          var md = miter.current;
          print("current metadata value {${md.reflectee.g}}");
        }
      }
    }
  }

  void run() {
    while (!idle && !finished) {
      idle = true;
      step();
    }
  }
}

class Reg<T> {
  T get val => _val;
  void set val(T newval) {
    _shadow = newval;
  }

  T _val;
  T _shadow;
  final name;
  Reg(T val, [name = "Reg"]) : this.name = name {
    this._val = val;
    this._shadow = val;
    // this is a hack -- we should be able to walk the class definition to find the state elements
    Module.registers.add(this);
  }
  T read() {
    return val;
  }

  void update() {
    if (this._val != this._shadow) {
      this._val = this._shadow;
      print("updated $name to $_val");
    }
  }
}

class FIFO1<T> extends Module {
  Reg<T> val;
  Reg<bool> full;

  FIFO1(name)
      : super(name),
        val = new Reg<T>(0, "FIFO1.val"),
        full = new Reg<bool>(false, "FIFO1.full") {}

  @guard("!full.val")
  void enq(T v) {
    if (!full.val) {
      val.val = v;
      full.val = true;
    }
  }

  @guard("full.val")
  T first() {
    if (full.val)
      return val.val;
    else
      return null;
  }

  @guard("full.val")
  void deq() {
    if (full.val) {
      full.val = false;
    }
  }

  bool notEmpty() => full.val;

  bool notFull() => !full.val;
}
