import std::io;
import std::collections::list;
import std::collections::map;

def Vector2 = int[<2>];

fn uint Vector2.hash(self) => self.x * 31 + self.y;

struct Region {
  char label;
  List(<Vector2>) positions;
}

struct Map {
  List(<String>) lines;
  HashMap(<int, Region*>) regions;
  Vector2 bounds;
}

fn bool Map.vec_in_bounds(&self, Vector2 pos) {
  return pos.comp_ge({ 0, 0 }).and() && pos.comp_lt(self.bounds).and();
}

fn char Map.get(&self, Vector2 pos) @operator([]) {
  return self.lines[(usz)pos.y][(usz)pos.x];
}

Vector2[] directions = {{-1, 0}, {1, 0}, {0,-1}, {0,1}};

fn Region* Map.fill_region(&self, Vector2 pos, int region_id, Region* region = null) {
  char ch = self.get(pos);
  if (region == null) {
    region = self.regions.@get_or_set(region_id, mem::new(Region));
    region.label = ch;
  }

  region.positions.push(pos);

  foreach (direction: directions) {
    Vector2 adjacent = pos + direction;
    if (!self.vec_in_bounds(adjacent) || region.positions.contains(adjacent)) continue;

    if (self.get(adjacent) == ch) self.fill_region(adjacent, region_id, region);
  }

  return region;
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

  map.bounds = { map.lines[0].len, (int)map.lines.len() };

  List(<Vector2>) assigned_positions;
  assigned_positions.temp_init();

  int region_id = 0;

  for (int y = 0; y < map.bounds.y; y++) {
    String line = map.lines[y];
    for (int x = 0; x < map.bounds.x; x++) {
      if (assigned_positions.contains({x,y})) continue;

      char ch = line[x];
      Vector2 pos = {x,y};

      Region* region = map.fill_region(pos, region_id);

      assigned_positions.add_all(&region.positions);

      region_id++;
    }
  }

  usz price, price_bulk;

  map.regions.@each(;int id, Region* region) {
    usz perimeter, sides;
    foreach (position: region.positions) {
      foreach (direction: directions) {
        Vector2 new_pos = position + direction;
        if (region.positions.contains(new_pos)) continue;
        perimeter++;

        // Check for a neighbour sharing the same side
        bool has_clockwise = region.positions.contains(position + {-direction.y, direction.x});
        // Check for a corner neighbour closing this side
        bool has_corner = region.positions.contains(position + {-direction.y, direction.x} + direction);
        if (!has_clockwise || has_corner) sides++;
      }
    }

    price += perimeter * region.positions.len();
    price_bulk += sides * region.positions.len();
  };

  io::printfn("Total price: %s", price);
  io::printfn("Total price for bulk: %s", price_bulk);
}
