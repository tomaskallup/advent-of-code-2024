import std::io;
import std::collections::list;

def Key = char[5];
def Lock = char[5];

List(<Key>) keys;
List(<Lock>) locks;

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");
  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  keys.temp_init();
  locks.temp_init();

  bool first_line = true;

  while (try line = io::treadline(&input)) {
    // Keys have empty row at the top
    bool is_key = line[0] == '.';

    usz index;

    if (is_key) {
      index = keys.len();
      keys.push({[0..4] = 0});
    } else {
      index = locks.len();
      locks.push({[0..4] = 1});
    }

    while (try next_line = io::treadline(&input)) {
      if (next_line == "") {
        break;
      }

      foreach (column, ch: next_line) {
        if (ch == '#') {
          if (is_key) {
            keys[index][column]++;
          } else {
            locks[index][column]++;
          }
        }
      }
    }
  }

  usz valid_combinations;
  foreach (lock: locks) {
    foreach KEYLOOP: (key: keys) {
      for(uint i; i < key.len; i++) {
        if (key[i] + lock[i] > 7) continue KEYLOOP;
      }
      valid_combinations++;
    }
  }

  io::printfn("Valid key/lock combinations: %d", valid_combinations);
}
