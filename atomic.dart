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
  final Guard guard;
  guard(this.guard);
}

class Module {
  var name;
  list<Rule> rules;
  list<Register> registers;
  var idle = true;
  var finished = false;

  Module(this.name) {
    rules = [];
    registers = [];
    themodule = this;
    idle = false;
    print("set themodule");
  }

  void addRule(name, Guard guard, Body body) {
    rules.add(new Rule(name, guard, body));
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
  Reg(T val) {
    this._val = val;
    this._shadow = val;
    if (themodule != null) {
      // this is a hack -- we should be able to walk the class definition to find the state elements
      themodule.registers.add(this);
    }
  }
  T read() {
    return val;
  }

  void update() {
    if (this._val != this._shadow) {
      this._val = this._shadow;
      print("updated to $_val");
    }
  }
}

class FIFO1<T> extends Module {
  Reg<T> val;
  Reg<bool> full;

  FIFO1(name)
      : super(name),
        full = new Reg<bool>(false) {}

  @guard(() => !full.val)
  void enq(T v) {
    if (!full) {
      val.val = v;
      full.val = true;
    }
  }

  @guard(() => full.val)
  T first() {
    if (full.val)
      return val.val;
    else
      return null;
  }

  @guard(() => full.val)
  void deq() {
    if (full.val) {
      full.val = false;
    }
  }

  bool notEmpty() => full.val;
  bool notFull() => !full.val;
}
