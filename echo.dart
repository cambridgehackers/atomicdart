import 'atomic.dart';

abstract class EchoIndication extends Module {
  void heard(int x);
}

class Echo extends Module {
  FIFO1<int> delay;
  EchoIndication indication;

  Echo(var name) : super(name) {
    delay = new FIFO1<int>("delayFifo");

    addRule("afterDelay", () => delay.pipeOut.notEmpty(), () {
      var val = delay.pipeOut.gfirst();
      print("afterDelay: $val");
      if (indication != null) {
        indication.heard(val);
        delay.pipeOut.gdeq();
      }
    });
  }

  @guard("delay.pipeIn.notFull()")
  void say(int x) {
    delay.pipeIn.genq(x);
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

    for (var i = 0; i < 1; i++) {
      addRule("startup", () => !ran.val, () {
        // use a "function expression invocation" rather than a "method invocation" to test the analyzer
        var says = [echo.say];
        says[i](22);
        ran.val = true;
      });
    }
  }
}

void main() {
  EchoTestbench tb = new EchoTestbench();
  Module.describeModules();
  tb.run();
}
