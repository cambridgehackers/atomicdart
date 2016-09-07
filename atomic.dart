import "dart:mirrors";
import "analyzer.dart";

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

  Module([this.name = "Module"]) {
    idle = false;
    modules.add(this);
  }

  void addRule(name, Guard guard, Body body) {
    describeObject(body);
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

  static void describeObject(o) {
    var mirror = reflect(o);
    print("reflection is $mirror");
    var function = mirror.function;
    print("reflection.function is $function");
    print("reflection.function.owner is ${function.owner}");
    print("reflection.function.simpleName is ${function.simpleName}");
    print("reflection.function.qualifiedName is ${function.qualifiedName}");
    print("reflection.location is ${function.location}");
    print("reflection.location is ${function.location.sourceUri}");
    print("reflection function.source is ${function.source}");
    var cu = parseDartLambdaString(
        "void body ${function.source}", function.location.sourceUri.path);
    print("compilation unit $cu");
    var visitor = new MyAstVisitor();
    var v = visitor.visitCompilationUnit(cu);
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

class PipeOut<T> {
  bool notEmpty();
  T first();
  void deq();
}

class PipeIn<T> {
  bool notFull();
  void enq();
}

class _Fifo1PipeOut<T> extends PipeOut<T> {
  Fifo1<T> _fifo;
  _Fifo1PipeOut(this._fifo) {}
  @guard("_fifo._full.val")
  T first() {
    if (_fifo._full.val)
      return _fifo._val.val;
    else
      return null;
  }

  @guard("_fifo._full.val")
  void deq() {
    if (_fifo._full.val) {
      _fifo._full.val = false;
    }
  }

  bool notEmpty() => _fifo._full.val;
}

class _Fifo1PipeIn<T> extends PipeIn<T> {
  Fifo1<T> _fifo;
  _Fifo1PipeIn(this._fifo) {}

  @guard("!_fifo._full.val")
  void enq(T v) {
    if (!_fifo._full.val) {
      _fifo._val.val = v;
      _fifo._full.val = true;
    }
  }

  bool notFull() => !_fifo._full.val;
}

class FIFO1<T> extends Module {
  Reg<T> _val;
  Reg<bool> _full;

  PipeOut<T> pipeOut;
  PipeIn<T> pipeIn;

  FIFO1(name)
      : super(name),
        _val = new Reg<T>(0, "FIFO1.val"),
        _full = new Reg<bool>(false, "FIFO1.full") {
    pipeOut = new _Fifo1PipeOut<T>(this);
    pipeIn = new _Fifo1PipeIn<T>(this);
  }
}
