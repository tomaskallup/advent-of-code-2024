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

fn bool check_pair(long expected, long acc, long[] rest, Operator[] operators) {
  if (rest.len == 1) {
    foreach (operator: operators) {
      if (eval_operator(acc, rest[0], operator) == expected) return true;
    }
    return false;
  }
  foreach (operator: operators) {
    if (check_pair(expected, eval_operator(acc, rest[0], operator), rest[1..], operators)) return true;
  }
  return false;
}

fn bool solve(Equation equation, Operator[] operators) {
  long expected = equation.first;
  long[] numbers = equation.second;

  return check_pair(expected, 0, numbers, operators);
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

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

  long valid_sum_first = 0;
  long valid_sum_second = 0;

  foreach (equation: equations) {
    if (solve(equation, { Operator.ADD, Operator.MUL })) {
      valid_sum_first += equation.first;
      valid_sum_second += equation.first;
    } else if (solve(equation, { Operator.ADD, Operator.MUL, Operator.CONCAT })) {
      valid_sum_second += equation.first;
    }
  }

  io::printfn("Valid equations sum: %d", valid_sum_first);
  io::printfn("Valid equations sum (with ||): %d", valid_sum_second);
}
