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
  return string::tformat("%d,%d", self.x, self.y);
}

struct Guard {
  Vector2 position;
  Vector2 direction;
  HashMap(<String, List(<Vector2>)*>) visited_nodes;
}

fn bool Guard.can_loop(&self) {
  // Create a rotated copy
  Guard copy;
  copy.position = self.position;
  copy.direction = { -self.direction.y, self.direction.x };
  copy.visited_nodes.temp_init();

  // Check if the copy gets stuck in a loop
  while (copy.advance()) {
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

fn bool Guard.advance(&self) {
  bool obstacle_in_front = false;

  String key = self.position.to_key();
  List(<Vector2>)* directions = self.visited_nodes.@get_or_set(key, mem::temp_new(List(<Vector2>)));
  if (!directions.contains(self.direction)) directions.push(self.direction);

  Vector2 new_pos;
  Vector2 start_direction = self.direction;
  while(true) {
    new_pos = self.position + self.direction;
    bool left_map = new_pos.y < 0 || new_pos.x < 0 || new_pos.y >= map_height || new_pos.x >= map_width;

    if (left_map) return false;

    if (map[new_pos.y][new_pos.x] != '#') {
      break;
    }

    self.direction = { -self.direction.y, self.direction.x };
  }

  self.position = new_pos;

  return true;
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

  while(guard.advance()) {
    Vector2 obstacle_pos = guard.position + guard.direction;
    if (obstacle_pos != start_pos && !loopable_positions.contains(obstacle_pos) && guard.can_loop()) {
      loopable_positions.push(obstacle_pos);
    }
  }

  io::printfn("Visited nodes: %d", guard.visited_nodes.len());
  io::printfn("Loopable positions: %d", loopable_positions.len());
}
