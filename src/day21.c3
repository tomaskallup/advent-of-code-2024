import std::io;
import std::math;
import std::collections::list;
import std::sort;

def Vector2 = int[<2>];

fn uint Vector2.hash(self) => self.x * 300 + self.y;

/*
  Intended usage: (target - pos).to_directions();
*/
fn String Vector2.to_directions(self) {
  long count = (long)math::abs(self).sum();
  char[] str = mem::temp_new_array(char, count + 1);
  usz pos;

  while (self.x > 0) {
    str[pos++] = '>';
    self.x--;
  }
  while (self.x < 0) {
    str[pos++] = '<';
    self.x++;
  }

  while (self.y < 0) {
    str[pos++] = '^';
    self.y++;
  }
  while (self.y > 0) {
    str[pos++] = 'v';
    self.y--;
  }

  str[pos] = 'A';

  return (String)str;
}

fn Vector2 numeric_pos(char button) {
  switch (button) {
    case 'A': return {2,3};
    case '0': return {1,3};
    // Blank space
    case 'X': return {0,3};
    case '1': return {0,2};
    case '2': return {1,2};
    case '3': return {2,2};
    case '4': return {0,1};
    case '5': return {1,1};
    case '6': return {2,1};
    case '7': return {0,0};
    case '8': return {1,0};
    case '9': return {2,0};
  }

  unreachable("Invalid button %c", button);
}

fn Vector2 directional_pos(char button) {
  switch (button) {
    case 'A': return {2,0};
    case '^': return {1,0};
    // Blank space
    case 'X': return {0,0};
    case '<': return {0,1};
    case 'v': return {1,1};
    case '>': return {2,1};
  }

  unreachable("Invalid button %c", button);
}

List(<String>) codes;

struct State {
  Vector2[] keypads;
}

fn void State.reset(&self, usz count) {
  self.keypads = mem::temp_new_array(Vector2, count);

  self.keypads[0] = numeric_pos('A');
  usz index = 0;
  while (++index < count) {
    self.keypads[index] = directional_pos('A');
  }
}

struct UnprocessedButton {
  String remaining;
  String current;
}

fn String[] get_combinations(String str) {
  if (!str.len) return {};

  List(<String>) buttons;
  buttons.temp_init();
  List(<UnprocessedButton>) unprocessed_buttons;
  unprocessed_buttons.temp_init();
  unprocessed_buttons.push({str[0:^1], ""});

  while(try button = unprocessed_buttons.pop()) {
    char prev;
    foreach(index, ch: button.remaining) {
      if (prev == ch) continue;
      prev = ch;
      String new_remaining = button.remaining[0:index];
      if (index < button.remaining.len - 1) new_remaining = new_remaining.tconcat(button.remaining[index+1..]);
      UnprocessedButton new_button = {
        new_remaining,
        button.current.tconcat({ch}),
      };
      if (!new_remaining.len) {
        buttons.push(new_button.current.tconcat("A"));
      } else {
        unprocessed_buttons.push(new_button);
      }
    }
  }

  return buttons.array_view();
}

fn bool State.validate_buttons(&self, usz keypad, String buttons) {
  Vector2 blank = keypad == 0 ? numeric_pos('X') : directional_pos('X');
  Vector2 new_pos = self.keypads[keypad];

  // No need to validate the `A` at the end
  foreach (index, direction: buttons[0:^1]) {
    switch(direction) {
      case '<': new_pos += {-1, 0};
      case '>': new_pos += {1, 0};
      case '^': new_pos += {0, -1};
      case 'v': new_pos += {0, 1};
    }

    if (new_pos == blank) {
      return false;
    }
  }

  return true;
}

fn usz State.move_keypad_min(&self, usz keypad, char button) {
  // Last keypad is human, so we don't need to check all ways to get to a button, we just push it.
  if (keypad == self.keypads.len - 1) return 1;

  usz result = usz.max;

  Vector2 target = keypad == 0 ? numeric_pos(button) : directional_pos(button);
  Vector2 to_move = target - self.keypads[keypad];

  String directions = to_move.to_directions();
  String winner;

  // We are already there, so we just need to confirm
  if (directions == "A") return 1;

  foreach(combination_directions: get_combinations(directions)) {
    // Ensure the combination is valid
    if (self.validate_buttons(keypad, combination_directions)) {
      usz combination_cost;
      foreach (next_button: combination_directions) {
        combination_cost += self.move_keypad_min(keypad + 1, next_button);
      }

      if (combination_cost < result) {
        result = combination_cost;
        winner = combination_directions;
      }
    }
  }

  /* if (keypad == self.keypads.len - 2) {
    if (!winner.len) {
      io::printfn("No winner for %d -> %c (%s)", keypad, button, directions);
    } else {
      io::printfn("Winner %d -> %c: %d -> %s", keypad, button, keypad + 1, winner);
    }
  } */
  self.keypads[keypad] = target;

  return result;
}

fn usz State.solve(&self, String code) {
  usz result;
  foreach (button: code) {
    result += self.move_keypad_min(0, button);
  }

  return result;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  
  codes.temp_init();

  while (try line = io::treadline(&input)) {
    codes.push(line);
  }

  State state;

  io::printn(codes);

  state.reset(2);
  io::printn(state);
  usz result;
  foreach (code: codes) {
    state.reset(4);
    int code_num = code[0..^2].to_int()!!;
    usz length = state.solve(code);
    usz complexity = length * code_num;
    io::printfn("Solved code %s: %d (%d * %d)", code, complexity, length, code_num);
    result += complexity;
  }

  io::printfn("Complexity for all codes: %d", result);
}
