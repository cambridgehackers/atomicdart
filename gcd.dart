import 'atomic.dart';

class Gcd extends Module {
  Reg<int> n;
  Reg<int> m;
  Gcd(int _n, int _m) : super(name: "gcd") {
    print("Gcd filling in body");
    n = new Reg<int>(_n, 32, "N");
    m = new Reg<int>(_m, 32, "M");

    action("swap", () => (n.val > m.val && m.val != 0), () {
      n.val = m.val;
      m.val = n.val;
    });

    action("sub", () => (n.val <= m.val && m.val != 0), () {
      return m.val = m.val - n.val;
    });

    action("result", () => m.val == 0, () {
      var gcd = n.val;
      print("Gcd Result: $gcd");
      finish();
    });
  }
}

void main() {
  print("instantiating Gcd");
  var gcd = new Gcd(3, 6);
  gcd.emitVerilog();
  gcd.run();
  print("done");
}
