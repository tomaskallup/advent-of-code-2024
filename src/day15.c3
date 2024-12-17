import std::io;
import std::collections::list;

def Vector2 = int[<2>];

fn uint Vector2.hash(self) => self.x * 31 + self.y;

struct Map {
  List(<String>) lines;
  Vector2 bounds;
  Vector2 robot;
}

fn bool Map.vec_in_bounds(self, Vector2 pos) {
  return pos.comp_ge({ 0, 0 }).and() && pos.comp_lt(self.bounds).and();
}

fn char Map.get(self, Vector2 pos) @operator([]) {
  return self.lines[(usz)pos.y][(usz)pos.x];
}

fn char Map.set(self, Vector2 pos, char ch) @operator([]=) {
  return self.lines[(usz)pos.y][(usz)pos.x] = ch;
}

fn void Map.print(self) {
  foreach (line: self.lines) {
    io::printn(line);
  }
}

DString commands;
usz command_index;

fn bool Map.can_move(self, Vector2 pos, Vector2 direction, bool check_neighbour = true) {
  Vector2 new_pos = pos + direction;
  if (!self.vec_in_bounds(new_pos) || self[new_pos] == '#') return false;

  // Moving a block horizontally, check neighbour
  if (direction.y != 0 && check_neighbour) {
    if (self[pos] == '[' && !self.can_move(pos + {1, 0}, direction, false)) return false;
    if (self[pos] == ']' && !self.can_move(pos - {1, 0}, direction, false)) return false;
  }

  char next_char = self[new_pos];
  if (next_char == '[' || next_char == ']' || next_char == 'O') {
    if (!self.can_move(new_pos, direction)) return false;
  }

  return true;
}

fn bool Map.move_block(&self, Vector2 pos, Vector2 direction, bool check_neighbour = true) {
  if (!self.can_move(pos, direction, check_neighbour)) return false;
  Vector2 new_pos = pos + direction;

  // Moving a block horizontally, check neighbour
  if (direction.y != 0 && check_neighbour) {
    if ((*self)[pos] == '[' && !self.move_block(pos + {1, 0}, direction, false)) return false;
    if ((*self)[pos] == ']' && !self.move_block(pos - {1, 0}, direction, false)) return false;
  }

  char next_char = (*self)[new_pos];
  if (next_char == '[' || next_char == ']' || next_char == 'O') {
    if (!self.move_block(new_pos, direction)) return false;
  }

  (*self)[new_pos] = (*self)[pos];
  (*self)[pos] = '.';

  return true;
}

fn void Map.move_robot(&self) {
  Vector2 direction;
  switch (commands[command_index++]) {
    case '<': direction = {-1, 0};
    case '>': direction = {1, 0};
    case '^': direction = {0, -1};
    case 'v': direction = {0, 1};
  }

  if (self.move_block(self.robot, direction)) {
    self.robot += direction;
  }
}

fn usz Map.calculate_gps(self, char target) {
  usz result;

  foreach (y, line: self.lines) {
    foreach (x, ch: line) {
      if (ch == target) result += 100 * y + x;
    }
  }

  return result;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  
  Map map;
  map.lines.temp_init();
  Map map_doubled;
  map_doubled.lines.temp_init();
  bool parsing_map = true;
  commands.temp_init();

  DString doubled_line;
  doubled_line.temp_init();
  while (try line = io::treadline(&input)) {
    if (line == "") {
      parsing_map = false;
      continue;
    }
    if (parsing_map) {
      map.lines.push(line);
      doubled_line.clear();
      foreach (x, ch: line) {
        if (ch == '@') {
          map.robot = {(int)x, (int)map.lines.len() - 1};
          map_doubled.robot = {(int)doubled_line.len(), (int)map_doubled.lines.len()};
          doubled_line.append("@.");
        } else if (ch == '#') {
          doubled_line.append("##");
        } else if (ch == 'O') {
          doubled_line.append("[]");
        } else if (ch == '.') {
          doubled_line.append("..");
        }
      }
      map_doubled.lines.push(doubled_line.tcopy_str());
    } else {
      commands.append(line);
    }
  }

  map.bounds = { map.lines[0].len, (int)map.lines.len() };
  map_doubled.bounds = { map_doubled.lines[0].len, (int)map_doubled.lines.len() };

  while (command_index < commands.len()) {
    map.move_robot();
  }

  io::printfn("Sum of boxes GPS: %d", map.calculate_gps('O'));

  command_index = 0;
  while (command_index < commands.len()) {
    map_doubled.move_robot();
  }

  io::printfn("Sum of boxes GPS doubled map: %d", map_doubled.calculate_gps('['));
}
