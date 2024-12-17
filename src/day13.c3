import std::io;
import std::math;
import std::collections::list;

def Vector2 = long[<2>];

macro Vector2 Vector2.gcd(self, Vector2 other) => {
  math::gcd(self.x, other.x),
  math::gcd(self.y, other.y),
};

macro Vector2 Vector2.lcm(self, Vector2 other) => {
  math::lcm(self.x, other.x),
  math::lcm(self.y, other.y),
};

struct Machine {
  Vector2 a, b;
  Vector2 prize;
}

List(<Machine>) machines;

fn Vector2 read_position(String line) {
  String[] positions = line.tsplit(": ")[1].tsplit(", ");

  return {
    positions[0][2..].to_int()!!,
    positions[1][2..].to_int()!!
  };
}

fn usz Machine.solve(self, long offset = 0) {
  // Thanks myhstichele & Chat GPT for Cramers
  long d = (long)self.a.x * self.b.y - (long)self.a.y * self.b.x;

  long prize_x = offset + self.prize.x;
  long prize_y = offset + self.prize.y;

  long d_x = prize_x * self.b.y - prize_y * self.b.x;
  long d_y = self.a.x * prize_y - self.a.y * prize_x;

  long a = d_x / d;
  long b = d_y / d;
  Vector2 result = self.a * a + self.b * b;
  if (result == { prize_x, prize_y }) return a * 3 + b;

  return 0;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  machines.temp_init();

  while (try line = io::treadline(&input)) {
    if (line == "") continue;

    Machine machine;
    machine.a = read_position(line);
    machine.b = read_position(io::treadline(&input)!!);
    machine.prize = read_position(io::treadline(&input)!!);
    machines.push(machine);
  }

  usz price, price_offset;

  foreach (machine: machines) {
    price+=machine.solve();
    price_offset+=machine.solve(10000000000000);
  }

  io::printfn("Minimal price: %d", price);
  io::printfn("Minimal price offset: %d", price_offset);
}
