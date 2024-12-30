import std::io;
import std::collections::list;
import std::math::vector;

struct Map {
  List(<String>) lines;
  Vec2f bounds;
}

fn bool Map.vec_in_bounds(&self, Vec2f pos) {
  return pos.comp_ge({ 0, 0 }).and() && pos.comp_lt(self.bounds).and();
}

fn char Map.get(&self, Vec2f pos) @operator([]) {
  return self.lines[(usz)pos.y][(usz)pos.x];
}

fn usz Map.check_branches(&self, Vec2f pos, List(<Vec2f>)* discovered, char ch = '0') {
  usz result;
  if (!self.vec_in_bounds(pos)) return result;

  if ((*self)[pos] != ch) return result;

  if (ch == '9') {
    if (!discovered.contains(pos)) discovered.push(pos);
    return 1;
  }

  result += self.check_branches(pos + {1.0,0.0}, discovered, ch + 1);
  result += self.check_branches(pos + {0.0,1.0}, discovered, ch + 1);
  result += self.check_branches(pos - {1.0,0.0}, discovered, ch + 1);
  result += self.check_branches(pos - {0.0,1.0}, discovered, ch + 1);

  return result;
}

Map map;

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  map.lines.temp_init();

  while (try line = io::treadline(&input)) {
    map.lines.push(line);
  }

  map.bounds = { (float)map.lines[0].len, (float)map.lines.len() };
  
  usz result;
  usz rating;

  List(<Vec2f>) discovered;
  discovered.temp_init();
  foreach (y, line: map.lines) {
    foreach (x, ch: line) {
      if (ch == '0') {
        discovered.clear();

        rating += map.check_branches({(float)x,(float)y}, &discovered);

        result += discovered.len();
      }
    }
  }

  io::printfn("Trailhead score: %d", result);
  io::printfn("Trailhead rating: %d", rating);
}
