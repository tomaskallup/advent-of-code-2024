import std::io;
import std::ascii;

enum State {
  FUNC,
  FIRST_NUMBER,
  SECOND_NUMBER,
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  long result = 0;
  long result_with_cond = 0;
  usz valid_count = 0;
  usz valid_enabled_count = 0;
  State state = State.FUNC;
  bool mul_enabled = true;

  DString tokens;
  tokens.temp_init();
  long[2] numbers;

  while (try c = input.read_byte()) {
    switch (state) {
      case State.FIRST_NUMBER:
      case State.SECOND_NUMBER:
        char ending = state == State.FIRST_NUMBER ? ',' : ')';
        if (c == ending) {
          if (tokens.len() > 3 || tokens.len() < 1) {
            tokens.clear();
            state = State.FUNC;
            nextcase state;
          }

          short index = state == State.FIRST_NUMBER ? 0 : 1;

          numbers[index] = tokens.str_view().to_long()!!;

          state = state == State.FIRST_NUMBER ? State.SECOND_NUMBER : State.FUNC;

          tokens.clear();

          if (state == State.FUNC) {
            long mult = numbers[0] * numbers[1];
            result += mult;
            valid_count++;
            if (mul_enabled) {
              valid_enabled_count++;
              result_with_cond += mult;
            }

            nextcase state;
          }
        } else if (!ascii::is_digit(c)) {
          tokens.clear();
          state = State.FUNC;
          nextcase state;
        } else {
          tokens.append(c);
        }
      case State.FUNC:
        tokens.append(c);

        if (c == '(') {
          if (tokens.str_view().ends_with("mul(")) {
            state = State.FIRST_NUMBER;
            tokens.clear();
          } else if (try char next_c = input.read_byte()) {
            if (next_c == ')') {
              if (tokens.str_view().ends_with("don't(")) {
                mul_enabled = false;
              } else if (tokens.str_view().ends_with("do(")) {
                mul_enabled = true;
              }
              tokens.clear();
            } else {
              tokens.clear();
              tokens.append(next_c);
            }
          }
        }
    }
  }

  io::printfn("Valid w/o conditions:  %d", valid_count);
  io::printfn("Valid with conditions: %d", valid_enabled_count);
  io::printfn("Sum w/o conditions:  %d", result);
  io::printfn("Sum with conditions: %d", result_with_cond);
}
