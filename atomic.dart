import "dart:mirrors";
import "analyzer.dart";

var themodule;
typedef bool Guard();
typedef void Body();

class Clock {
  var name;
  var period;
  Clock({var this.name, var this.period}) {}
}

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

class Module {
  var name;
  var idle = true;
  var finished = false;
  static list<Module> modules = [];
  static list<Rule> rules = [];
  static list<Register> registers = [];
  Clock clock;

  Module({this.name: "Module", this.clock: null}) {
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
        //print("declMirror.type ${declMirror.type}");
        print("declMirror.owner ${declMirror.owner}");

        try {
          // fetch the value if fetchable
          var field = moduleMirror.getField(declMirror.simpleName);
          print("declMirror value $field");
        } catch (exception, stackTrace) {}

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

typedef void Method0();
typedef void Method1<T>(T v);
typedef void Method2<T1, T2>(T v);
typedef R Value0<R>();
typedef R Value1<R, T>(T v);
typedef R Value2<R, T1, T2>(T v);

class GuardedMethod {
  final method;
  final Guard guard;
  GuardedMethod(this.method, [this.guard = (() => true)]);
}

class GuardedValue0<R> {
  Guard guard;
  Value0<R> _method;
  GuardedValue0(Guard this.guard, Method this._method) {}
  R call() => _method();
}

class GuardedMethod0 {
  Guard guard;
  Method0 _method;
  GuardedMethod0(Guard this.guard, Method this._method) {}
  void call() => _method();
}

class GuardedMethod1<T> {
  Guard guard;
  Method1<T> _method;
  GuardedMethod1(Guard this.guard, Method1<T> this._method) {}
  void call(T v) => _method(v);
}

class GuardedMethod2<T1, T2> {
  Guard guard;
  Method2<T1, T2> _method;
  GuardedMethod2(Guard this.guard, Method2<T1, T2> this._method) {}
  void call(T1 v1, T2 v2) => _method(v1, v2);
}

class PipeOut<T> {
  bool notEmpty();

  T first();
  void deq();

  // guarded versions
  GuardedValue0<T> gfirst;
  GuardedMethod0 gdeq;
}

class PipeIn<T> {
  bool notFull();
  void enq();

  // guarded version
  GuardedMethod1<T> genq;
}

class _Fifo1PipeOut<T> extends PipeOut<T> {
  Fifo1<T> _fifo;
  _Fifo1PipeOut(this._fifo) {
    gfirst = new GuardedValue0<T>(() => _fifo._full.val, first);
    gdeq = new GuardedMethod0(() => _fifo._full.val, deq);
  }
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
  _Fifo1PipeIn(this._fifo) {
    genq = new GuardedMethod1<T>(() => !_fifo._full.val, enq);
  }

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
      : super(name: name),
        _val = new Reg<T>(0, "FIFO1.val"),
        _full = new Reg<bool>(false, "FIFO1.full") {
    pipeOut = new _Fifo1PipeOut<T>(this);
    pipeIn = new _Fifo1PipeIn<T>(this);
  }
}
