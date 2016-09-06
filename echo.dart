import 'atomic.dart';

abstract class EchoIndication extends Module {
  void heard(int x);
}

class Echo extends Module {
  FIFO1<int> delay;
  EchoIndication indication;

  Echo(var name) : super(name) {
    delay = new FIFO1<int>("delayFifo");

    addRule("afterDelay", () => delay.notEmpty(), () {
      var val = delay.first();
      print("afterDelay: $val");
      if (indication != null) {
        indication.heard(val);
        delay.deq();
      }
    });
  }

  @guard("m.delay.notFull()")
  void say(int x) {
    delay.enq(x);
  }
}

class EchoIndicationTB extends Module {
  EchoIndicationTB() : super("EchoIndicationTB") {}
  void heard(int x) {
    print("EchoIndication.heard $x");
  }
}

class EchoTestbench extends Module {
  Echo echo;
  EchoIndicationTb indication;
  Reg<bool> ran;
  EchoTestbench()
      : super("EchoTestbench"),
        echo = new Echo("Echo"),
        indication = new EchoIndicationTB(),
        ran = new Reg<bool>(false, "Echo.ran") {
    // connect echo indication
    echo.indication = indication;

    addRule("startup", () => !ran.val, () {
      echo.say(22);
      ran.val = true;
    });
  }
}

void main() {
  EchoTestbench tb = new EchoTestbench();
  tb.describeModules();
  tb.run();
}
