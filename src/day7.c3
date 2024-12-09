import std::io;
import std::collections::tuple;
import std::collections::list;
import std::math;

def Equation = Tuple(<long, long[]>);
List(<Equation>) equations;

enum Operator {
  ADD,
  MUL,
  CONCAT,
}

fn int num_digits (long n) {
    int r = 1;
    if (n < 0) n = (n == long.min) ? long.max: -n;
    while (n > 9) {
        n /= 10;
        r++;
    }
    return r;
}

fn long eval_operator(long a, long b, Operator op) {
  if (op == Operator.ADD) return a + b;
  if (op == Operator.MUL) return a * b;
  if (op == Operator.CONCAT) return a * (long)math::pow(10, num_digits(b)) + b;

  unreachable();
}

fn bool check_pair(long expected, long acc, long[] rest) {
  if (rest.len == 1) {
    if (eval_operator(acc, rest[0], Operator.ADD) == expected) return true;
    if (eval_operator(acc, rest[0], Operator.MUL) == expected) return true;
    if (eval_operator(acc, rest[0], Operator.CONCAT) == expected) return true;
    return false;
  }
  if (check_pair(expected, eval_operator(acc, rest[0], Operator.ADD), rest[1..])) return true;
  if (check_pair(expected, eval_operator(acc, rest[0], Operator.MUL), rest[1..])) return true;
  if (check_pair(expected, eval_operator(acc, rest[0], Operator.CONCAT), rest[1..])) return true;

  return false;
}

fn bool solve(Equation equation) {
  long expected = equation.first;
  long[] numbers = equation.second;

  return check_pair(expected, 0, numbers);
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  equations.temp_init();

  while (try line = io::treadline(&input)) {
    Equation* equation = mem::temp_new(Equation);
    String[] split = line.tsplit(": ");
    long expected = split[0].to_long()!!;
    String[] raw_numbers = split[1].tsplit(" ");
    long[] numbers = mem::temp_new_array(long, raw_numbers.len);
    foreach (i, number: raw_numbers) {
      numbers[i] = number.to_long()!!;
    }
    equation.first = expected;
    equation.second = numbers;
    equations.push(*equation);
  }

  long valid_sum = 0;

  foreach (equation: equations) {
    if (solve(equation)) valid_sum += equation.first;
  }

  io::printfn("Valid equations sum: %d", valid_sum);
}
