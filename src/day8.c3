import std::io;
import std::collections::list;
import std::collections::map;
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

fn void Map.set(&self, Vec2f pos, char ch) @operator([]=) {
  if (!self.vec_in_bounds(pos)) return;
  if (self.lines[(usz)pos.y][(usz)pos.x] != '.') return;
  self.lines[(usz)pos.y][(usz)pos.x] = ch;
}

fn usz Map.write(&self) {
  File output = file::open("map8.txt", "w")!!;
  defer output.close()!!;

  usz! len;

  foreach(line: self.lines) {
    len += output.write(line);
    len += output.write("\n");
  }

  return len!!;
}

Map map;

def Positions = List(<Vec2f>);

HashMap(<char, Positions*>) frequencies;

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  map.lines.temp_init();
  frequencies.temp_init();

  float y = 0;

  while (try line = io::treadline(&input)) {
    map.lines.push(line);
    foreach(x, c: line) {
      if (c == '.') continue;
      Positions* positions = frequencies.@get_or_set(c, mem::temp_new(Positions));
      if (!positions.allocator) positions.temp_init();
      positions.push({x,y});
    }
    y++;
  }

  map.bounds = { (float)map.lines[0].len, (float)map.lines.len()};

  Positions antinodes;
  antinodes.temp_init();
  Positions antinodes_resonant;
  antinodes_resonant.temp_init();

  frequencies.@each(;char frequency, Positions* positions) {
    foreach (index, position: positions) {
      foreach (position2: positions.array_view()[index+1..]) {
        if (position == position2) continue;

        Vec2f distance = position2 - position;
        Vec2f target1 = position - distance;
        Vec2f target2 = position2 + distance;

        Vec2f[2] possible_antinodes_part1 = {target1, target2};
        foreach(antinode: possible_antinodes_part1) {
          if (map.vec_in_bounds(antinode) && !antinodes.contains(antinode)) {
            map[antinode]='#';
            antinodes.push(antinode);
          }
        }

        Vec2f[2][2] possible_antinodes_part2 = {{ position, -distance }, { position2, distance }};
        foreach(antinode: possible_antinodes_part2) {
          Vec2f target = antinode[0];
          Vec2f direction = antinode[1];
          while (map.vec_in_bounds(target)) {
            if (!antinodes_resonant.contains(target)) {
              antinodes_resonant.push(target);

              map[target]='%';
            }

            target += direction;
          }
        }
      }
    }
  };

  map.write();

  io::printfn("Result: %d", antinodes.len());
  io::printfn("Result with resonant harmonics: %d", antinodes_resonant.len());
}
