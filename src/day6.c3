import std::io;
import std::collections::list;
import std::collections::map;
import std::collections::tuple;

def Vector2 = long[<2>];
List(<String>) map;
usz map_width;
usz map_height;
List(<Vector2>) loopable_positions;

fn String Vector2.to_key(&self) {
  return string::tformat("%d,%d", self.y, self.x);
}

macro bool Vector2.is_out_of_bounds(&self) {
  return self.y < 0 || self.x < 0 || self.y >= map_height || self.x >= map_width;
}

struct Guard {
  Vector2 position;
  Vector2 direction;
  Vector2 blockade;
  HashMap(<String, List(<Vector2>)*>) visited_nodes;
}

fn bool Guard.can_loop(&self, Vector2 blockade) {
  // Create a copy one step back (before the blockade)
  Guard copy;
  copy.position = self.position - self.direction;
  copy.direction = self.direction;
  copy.visited_nodes.temp_init();
  copy.blockade = blockade;

  defer {|
    if (blockade.to_key() == "101,91") {
      copy.write_map("map_101-91.txt");
    }
  |};

  // Check if the copy gets stuck in a loop
  while (copy.advance(true)) {
    // Simple check if we ended up back at the start
    if (copy.position == self.position && copy.direction == self.direction) return true;

    // Search visited nodes, if we already encountered this exact node with same position
    if (try visited_directions = copy.visited_nodes.get(copy.position.to_key())) {
      if (visited_directions.contains(copy.direction)) {
        return true;
      }
    }
  }

  return false;
}

fn bool Guard.advance(&self, bool custom_blockade = false) {
  bool obstacle_in_front = false;

  String key = self.position.to_key();
  List(<Vector2>)* directions = self.visited_nodes.@get_or_set(key, mem::temp_new(List(<Vector2>)));
  if (!directions.contains(self.direction)) directions.push(self.direction);

  Vector2 new_pos;
  Vector2 start_direction = self.direction;
  while(true) {
    new_pos = self.position + self.direction;
    bool left_map = new_pos.is_out_of_bounds();

    if (left_map) return false;

    char map_char = map[new_pos.y][new_pos.x];
    if (custom_blockade && new_pos == self.blockade) map_char = '#';

    if (map_char != '#') {
      break;
    }

    self.direction = { -self.direction.y, self.direction.x };
  }

  self.position = new_pos;

  return true;
}

fn usz Guard.write_map(&self, String name) {
  File output = file::open(name, "w")!!;

  usz! len;

  foreach(y, line: map) {
    foreach(x, ch: line) {
      Vector2 pos = {x,y};
      if (self.blockade == pos) { len+=output.write("O"); }
      else if (ch == '#') { len+=output.write("#"); }
      else if (self.position == pos) {
        switch (self.direction) {
          case {0, -1}: len+=output.write("^");
          case {0, 1}: len+=output.write("v");
          case {1, 0}: len+=output.write(">");
          case {-1, 0}: len+=output.write("<");
        }
      } else if (try visited_directions = self.visited_nodes.get(pos.to_key())) {
        if (visited_directions.len() > 1) {
          len+=output.write("+");
        } else if (visited_directions.get(0).x == 0) {
          len+=output.write("|");
        } else if (visited_directions.get(0).y == 0) {
          len+=output.write("-");
        }
      } else {
        len+=output.write(".");
      }
    }
    len+=output.write("\n");
  }

  return len!!;
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  map.temp_init();

  Guard guard;
  guard.visited_nodes.temp_init();

  while (try line = io::treadline(&input)) {
    map.push(line);

    if (line.len > map_width) map_width = line.len;

    if (try index = line.index_of_char('^')) {
      guard.position = {index, map.len()-1};
      guard.direction = {0, -1};
    } else if (try index = line.index_of_char('v')) {
      guard.position = {index, map.len()-1};
      guard.direction = {0, 1};
    } else if (try index = line.index_of_char('>')) {
      guard.position = {index, map.len()-1};
      guard.direction = {1, 0};
    } else if (try index = line.index_of_char('<')) {
      guard.position = {index, map.len()-1};
      guard.direction = {-1, 0};
    }
  }

  map_height = map.len();

  Vector2 start_pos = guard.position;

  do {
    Vector2 obstacle_pos = guard.position;
    /* if (obstacle_pos.to_key() == "101,91") {
      io::printn(obstacle_pos);
    } */
    if (obstacle_pos.is_out_of_bounds()) continue;

    if (try guard.visited_nodes.get(obstacle_pos.to_key())) continue;
    if (obstacle_pos != start_pos && guard.can_loop(obstacle_pos)) {
      loopable_positions.push(obstacle_pos);
    }
  } while(guard.advance());

  guard.write_map("map_original.txt");

  File output = file::open("my_out", "w")!!;

  foreach(obstacle_pos: loopable_positions) {
    output.write(obstacle_pos.to_key())!!;
    output.write("\n")!!;
  }

  io::printfn("Visited nodes: %d", guard.visited_nodes.len());
  io::printfn("Loopable positions: %d", loopable_positions.len());
}
