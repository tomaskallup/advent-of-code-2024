import std::io;
import std::collections::list;
import std::collections::map;
import std::collections::priorityqueue;

def Vector2 = int[<2>];

const Vector2 MAP_SIZE @if($feature(EXAMPLE)) = {7, 7};
const Vector2 MAP_SIZE @if(!$feature(EXAMPLE)) = {71, 71};
const usz BYTES_TO_FALL @if($feature(EXAMPLE)) = 12;
const usz BYTES_TO_FALL @if(!$feature(EXAMPLE)) = 1024;

fn uint Vector2.hash(self) => self.x * 31 + self.y;
fn uint Vector2.end_distance(self) => (MAP_SIZE - self).sum();
fn bool Vector2.in_bounds(self) => self.comp_ge({ 0, 0 }).and() && self.comp_lt(MAP_SIZE).and();

List(<Vector2>) bytes;

short[MAP_SIZE.x][MAP_SIZE.y] map;

struct PathNode {
  Vector2 position;
  PathNode* prev;
  uint cost, distance;
}

fn int PathNode.compare(self, PathNode other) {
  return self.distance - other.distance;
}

fn PathNode* create_path_node(Vector2 position, PathNode* prev = null) {
  PathNode* node = mem::temp_new(PathNode);
  node.position = position;
  node.cost = prev ? prev.cost + 1 : 0;
  node.prev = prev;
  node.distance = position.end_distance();

  return node;
}

fn void fill_map(usz time) {
  Vector2[] fallen_bytes = bytes.array_view()[:time];
  foreach (fallen_byte: fallen_bytes) map[fallen_byte.x][fallen_byte.y] = 1;
}

fn void print_map(PathNode* path = null) {
  while (path) {
    map[path.position.x][path.position.y] = 2;
    path = path.prev;
  }
  for(int y = 0; y < MAP_SIZE.y; y++) {
    for(int x = 0; x < MAP_SIZE.x; x++) {
      io::print(map[x][y] == 2 ? "O" : map[x][y] == 1 ? "#" : ".");
    }
    io::printn();
  }
}

fn PathNode* find_path(Vector2 start, Vector2 target) {
  List(<PathNode*>) queue;
  queue.temp_init();
  List(<Vector2>) walked_nodes;
  walked_nodes.temp_init();
  PathNode* start_node = create_path_node(start);
  PathNode* finish;

  queue.push(start_node);
  walked_nodes.push(start);

  Vector2[] directions = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};

  while (try node = queue.pop_first()) {
    if (node.position == target) {
      finish = node;
      break;
    }

    foreach(direction: directions) {
      Vector2 neighbor = node.position + direction;
      if (!neighbor.in_bounds() || map[neighbor.x][neighbor.y] == 1) continue;

      if (walked_nodes.contains(neighbor)) continue;

      walked_nodes.push(neighbor);

      queue.push(create_path_node(neighbor, node));
    }
  }

  return finish;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  bytes.temp_init();

  while (try line = io::treadline(&input)) {
    String[] parts = line.tsplit(",");
    bytes.push({
      parts[0].to_int()!!,
      parts[1].to_int()!!,
    });
  }
  
  fill_map(BYTES_TO_FALL);
  print_map();

  // Perform A*
  Vector2 start = {0, 0};
  Vector2 target = MAP_SIZE - {1, 1};
  PathNode* finish = find_path(start, target);

  if (!finish) {
    io::printn("No path to finish.");
  } else {
    print_map(finish);
    io::printfn("Cost to reach finish: %d", finish.cost);
    
    foreach (byte: bytes.array_view()[BYTES_TO_FALL..]) {
      map[byte.x][byte.y] = 1;
      PathNode* path = finish;
      PathNode* clash;
      while (path) {
        if (path.position == byte) {
          clash = path;
          break;
        }
        path = path.prev;
      }

      if (clash) {
        PathNode* new_path = find_path(start, target);
        if (new_path) {
          finish = new_path;
          continue;
        }

        io::printfn("Byte breaking the path to finish: %d,%d", byte.x, byte.y);
        break;
      }
    }
  }
}
