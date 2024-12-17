import std::io;
import std::collections::list;
import std::collections::map;

def Vector2 = int[<2>];

fn uint Vector2.hash(self) => self.x * 31 + self.y;

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

fn void Map.print(self, Reindeer* reindeer = null) {
  if (!reindeer) {
    foreach (line: self.lines) {
      io::printn(line);
    }
  } else {
    foreach (int y, line: self.lines) {
      foreach (int x, ch: line) {
        if (ch != '.') {
          io::printf("%c", ch);
        } else {
          if (try direction = reindeer.visited_positions.get({x,y})) {
            switch (direction) {
              case {1, 0}: io::print(">");
              case {-1, 0}: io::print("<");
              case {0, 1}: io::print("v");
              case {0, -1}: io::print("^");
            }
          } else {
            io::printf("%c", ch);
          }
        }
      }
      io::printn();
    }
  }
}

struct Reindeer {
  HashMap(<Vector2, Vector2>) visited_positions;
  Vector2 position;
  Vector2 direction;
  Vector2 custom_wall;
  usz score;
}

fn bool Reindeer.walk(&self, Map map, List(<Reindeer>)* branches) {
  usz cost;

  Vector2 forward = self.position + self.direction;
  
  Vector2 left = self.position + {self.direction.y, -self.direction.x};
  Vector2 right = self.position + {-self.direction.y, self.direction.x};

  Vector2 next_pos = {0,0};
  Vector2[] posibilities = {forward, left, right};

  self.visited_positions.set(self.position, self.direction);

  foreach OUTER: (possible_pos: posibilities) {
    if (possible_pos == self.custom_wall || !map.walkable(possible_pos) || self.visited_positions.has_key(possible_pos)) continue;
    if (next_pos == {0,0}) {
      next_pos = possible_pos;
      
      // We need to turn
      if (next_pos != forward) {
        cost += 1000;
      }
    } else {
      Reindeer branch;
      branch.position = self.position;
      branch.direction = possible_pos - self.position;
      branch.score = self.score + 1000;
      branch.custom_wall = next_pos;
      // Check for duplicates
      foreach (existing_branch: *branches) {
        if (existing_branch.position == branch.position && existing_branch.direction == branch.direction && existing_branch.score < branch.score) {
          continue OUTER;
        }
      }
      
      // @TODO: use temp_init_from_map once it's fixed
      branch.visited_positions.temp_init();
      self.visited_positions.@each(;Vector2 pos, Vector2 dir) {
        branch.visited_positions.set(pos, dir);
      };

      branches.push(branch);
    }
  }

  if (next_pos != {0,0}) {
    cost += 1;
    self.score += cost;
    self.direction = next_pos - self.position;
    self.position = next_pos;

    return map[next_pos] == '.';
  }

  // If none of the positions can be walked, we ran into a dead end
  return false;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  
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
  usz lowest = usz.max;
  List(<Reindeer>) branches;
  branches.temp_init();
  Reindeer initial_branch;
  initial_branch.position = map.start;
  initial_branch.direction = {1, 0};
  initial_branch.visited_positions.temp_init();
  branches.push(initial_branch);

  for(usz branch_id; branch_id < branches.len(); branch_id++) {
    Reindeer reindeer = branches[branch_id];
    usz start_score = reindeer.score;
    if (start_score > lowest) continue;
    while (reindeer.walk(map, &branches));

    if (reindeer.position == map.end) {
      if (reindeer.score < lowest) {
        lowest = reindeer.score;
      }
    }

    branches[branch_id] = reindeer;
  }

  io::printfn("Lowest score: %d", lowest);

  List(<Vector2>) best_seats;
  best_seats.temp_init();

  foreach(reindeer: branches) {
    if (reindeer.score != lowest || reindeer.position != map.end) continue;
    
    foreach(pos: reindeer.visited_positions.tcopy_keys()) {
      if (!best_seats.contains(pos)) best_seats.push(pos);
    }
  }

  io::printfn("Best seats: %d", best_seats.len() + 1);
}
