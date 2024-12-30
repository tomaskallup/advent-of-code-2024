import std::io;
import std::collections::list;
import std::collections::map;
import std::math;

def Vector2 = int[<2>];

fn uint Vector2.hash(self) => self.x * 300 + self.y;

struct Path {
  Vector2 position;
  usz distance;
}

fn bool Path.equals(self, Path other) {
  return self.position == other.position;
}

List(<Path>) path;

Vector2[] directions = {
  {1,0},
  {-1,0},
  {0,1},
  {0,-1},
};

struct Map {
  List(<String>) lines;
  Vector2 bounds;
  Vector2 start, end;
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

fn bool Map.walkable(self, Vector2 pos) {
  if (!self.vec_in_bounds(pos)) return false;

  return self[pos] != '#';
}

fn void Map.print(self) {
  foreach (int y, line: self.lines) {
    foreach (int x, ch: line) {
      if (ch == '#') {
        io::printf("%c", ch);
      } else {
        if (path.contains({{x,y},0})) {
          if (ch == '.') { io::print("o"); }
          else { io::print("O"); }
        }
        else { io::print("."); }
      }
    }
    io::printn();
  }
}

struct Cheat {
  Vector2 start, end;
  usz save;
}

fn Cheat[] Map.check_cheats(self, usz allowed_steps = 2) {
  List(<Cheat>) cheats;
  cheats.temp_init();

  usz len = path.len();
  foreach (index, start_path: path) {
    // No need to check the last three nodes
    if (index > path.len() - 3) continue;
    foreach (end_path: path.array_view()[index+3..]) {
      usz distance = math::abs(end_path.position - start_path.position).sum();
      usz savings = end_path.distance - start_path.distance - distance;
      if (distance <= allowed_steps && savings > 0) {
        Cheat new_cheat = {start_path.position, end_path.position, savings};
        cheats.push(new_cheat);
      }
    }
  }

  return cheats.array_view();
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;
  
  Map map;
  map.lines.temp_init();

  while (try line = io::treadline(&input)) {
    map.lines.push(line);
    foreach (x, ch: line) {
      if (ch == 'S') {
        map.start = {(int)x, (int)map.lines.len() - 1};
      } else if (ch == 'E') {
        map.end = {(int)x, (int)map.lines.len() - 1};
      }
    }
  }

  map.bounds = { map.lines[0].len, (int)map.lines.len() };

  path.temp_init();

  Vector2 pos = map.start;
  usz distance;
  while (pos != map.end) {
    Vector2 previous_pos = path.len() ? path[path.len()-1].position : 0;
    path.push({ pos, distance++ });
    foreach (direction: directions) {
      Vector2 next_pos = pos + direction;
      if (next_pos == previous_pos || !map.walkable(next_pos)) continue;

      pos = next_pos;
      break;
    }
  }

  path.push({ map.end, distance++ });

  {|
    Cheat[] cheats = map.check_cheats();
    usz cheats_100_or_more;
    if (cheats.len) {
      foreach (cheat: cheats) {
        if (cheat.save >= 100) cheats_100_or_more += 1;
      }
    }

    io::printfn("Cheats which save atleast 100 with 2 picoseconds cheat time: %d", cheats_100_or_more);
  |};

  {|
    Cheat[] cheats = map.check_cheats(20);
    usz cheats_100_or_more;
    if (cheats.len) {
      foreach (cheat: cheats) {
        if (cheat.save >= 100) cheats_100_or_more += 1;
      }
    }
    io::printfn("Cheats which save atleast 100 with 20 picoseconds cheat time: %d", cheats_100_or_more);
  |};
}
