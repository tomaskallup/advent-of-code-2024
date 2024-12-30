import std::io;
import std::collections::list;

List(<String>) lines;

fn short search_up (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y-i][x] != ch) return 0;
  }

  return 1;
}

fn short search_down (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y+i][x] != ch) return 0;
  }

  return 1;
}

fn short search_left (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y][x-i] != ch) return 0;
  }

  return 1;
}

fn short search_right (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y][x+i] != ch) return 0;
  }

  return 1;
}
fn short search_up_left (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y-i][x-i] != ch) return 0;
  }

  return 1;
}

fn short search_up_right (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y-i][x+i] != ch) return 0;
  }

  return 1;
}

fn short search_down_left (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y+i][x-i] != ch) return 0;
  }

  return 1;
}

fn short search_down_right (usz x, usz y, String needle) {
  foreach(i, ch: needle) {
    if (lines[y+i][x+i] != ch) return 0;
  }

  return 1;
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  lines.temp_init();

  long result = 0;
  long result_x = 0;

  while (try line = io::treadline(&input)) {
    lines.push(line);
  }

  foreach(y, line: lines) {
    bool can_go_up = y >= 3;
    bool can_go_down = lines.size - y > 3;
    bool x_can_go_vert = y > 0 && y < lines.size - 1;
    foreach(x, ch: line) {
      bool can_go_left = x >= 3;
      bool can_go_right = line.len - x > 3;

      if (ch == 'X') {
        if (can_go_up) {
          result += search_up(x, y, "XMAS");
          if (can_go_left) result += search_up_left(x, y, "XMAS");
          if (can_go_right) result += search_up_right(x, y, "XMAS");
        }
        if (can_go_down) {
          result += search_down(x, y, "XMAS");
          if (can_go_left) result += search_down_left(x, y, "XMAS");
          if (can_go_right) result += search_down_right(x, y, "XMAS");
        }
        if (can_go_left) result += search_left(x, y, "XMAS");
        if (can_go_right) result += search_right(x, y, "XMAS");
      } else if (ch == 'A') {
        bool x_can_go_hor = x > 0 && x < line.len - 1;
        if (x_can_go_vert && x_can_go_hor) {
          int has_down_x = (int)search_down_right(x-1, y-1, "MAS") + search_down_left(x+1, y-1, "MAS");
          int has_up_x = (int)search_up_right(x-1, y+1, "MAS") + search_up_left(x+1, y+1, "MAS");
          long has_any_x = (long)has_down_x + has_up_x;
          if (has_any_x == 2) {
            result_x++;
          }
        }
      }
    }
  }

  io::printfn("XMAS count: %d", result);
  io::printfn("X-MAS count: %d", result_x);
}
