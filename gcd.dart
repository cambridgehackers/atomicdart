import 'atomic.dart';

class Gcd extends Module {
  Reg<int> n;
  Reg<int> m;
  Gcd(int _n, int _m) : super(name: "gcd") {
    n = new Reg<int>(_n);
    m = new Reg<int>(_m);

    addRule("swap", () => (n.val > m.val && m.val != 0), () {
      n.val = m.val;
      m.val = n.val;
    });

    addRule("sub", () => (n.val <= m.val && m.val != 0), () {
      return m.val = m.val - n.val;
    });

    addRule("result", () => m.val == 0, () {
      var gcd = n.val;
      print("Gcd Result: $gcd");
      finish();
    });
  }
}

void main() {
  print("instantiating Gcd");
  var gcd = new Gcd(3, 6);
  gcd.run();
  print("done");
}
