import std::io;
import std::collections::list;
import std::collections::map;
import std::math;

def Vector2 = int[<2>];

const Vector2 MAP_SIZE @if($feature(EXAMPLE)) = {11, 7};
const Vector2 MAP_SIZE @if(!$feature(EXAMPLE)) = {101, 103};

fn uint Vector2.hash(self) => self.x * 31 + self.y;

macro Vector2 wrap_around_bounds(self, Vector2 bounds) {
  long[<2>] result = (long[<2>])self;

  long x_diff = (long)math::abs(math::floor((float)result.x/bounds.x));
  long y_diff = (long)math::abs(math::floor((float)result.y/bounds.y));
  if (result.x >= bounds.x) result.x %= bounds.x * x_diff;
  if (result.y >= bounds.y) result.y %= bounds.y * y_diff;
  if (result.x < 0) result.x += bounds.x * x_diff;
  if (result.y < 0) result.y += bounds.y * y_diff;

  return (Vector2)result;
}

struct Robot {
  Vector2 initial_position;
  Vector2 position;
  Vector2 velocity;
}

List(<Robot>) robots;

fn Robot read_robot(String line) {
  String[] parts = line.tsplit(" ");
  String[] position_parts = parts[0][2..].tsplit(",");
  String[] velocity_parts = parts[1][2..].tsplit(",");

  Vector2 position = {
    position_parts[0].to_int()!!,
    position_parts[1].to_int()!!
  };

  Vector2 velocity = {
    velocity_parts[0].to_int()!!,
    velocity_parts[1].to_int()!!
  };

  return {
    position,
    position,
    velocity,
  };
}
fn void Robot.reset(&self) {
  self.position = self.initial_position;
}

fn void Robot.move(&self, usz times = 1) {
  long[<2>] new_pos = (long[<2>])self.position + (long[<2>])self.velocity * times;

  self.position = wrap_around_bounds(new_pos, MAP_SIZE);
}

fn usz[2][2] count_quadrants() {
  usz[2][2] quadrants;
  Vector2 borders = MAP_SIZE / 2;

  foreach (robot: robots) {
    if (robot.position.comp_eq(borders).or()) {
      continue;
    }
    Vector2 quadrant_coords = {
      robot.position.x > borders.x ? 1 : 0,
      robot.position.y > borders.y ? 1 : 0,
    };

    quadrants[quadrant_coords.y][quadrant_coords.x] += 1;
  }

  return quadrants;
}

fn int[MAP_SIZE.y][MAP_SIZE.x] build_map() {
  int[MAP_SIZE.y][MAP_SIZE.x] map;

  foreach(robot: robots) {
    map[robot.position.x][robot.position.y]++;
  }

  return map;
}

fn void print_map() {
  int[MAP_SIZE.y][MAP_SIZE.x] robot_positions = build_map();

  for(int y = 0; y < MAP_SIZE.y; y++) {
    for(int x = 0; x < MAP_SIZE.x; x++) {
      int count = robot_positions[x][y];
      if (count) {
        io::print(count);
      } else {
        io::print(".");
      }
    }

    io::printn();
  }
}

fn usz! search_for_tree() {
  foreach (&robot: robots) {
    robot.reset();
  }

  usz max_tries = MAP_SIZE.x * MAP_SIZE.y;
  usz tries = max_tries;

  while (tries-- > 0) {
    foreach (&robot: robots) {
      robot.move();
    }

    int[MAP_SIZE.y][MAP_SIZE.x] map = build_map();
    for (int y = 0; y < MAP_SIZE.y; y++) {
      int line = 0;
      for (int x = 0; x < MAP_SIZE.x; x++) {
        if (map[x][y] == 0) {
          line = 0;
          continue;
        }

        if (++line > 20) {
          return max_tries - tries;
        }
      }
    }
  }

  return SearchResult.MISSING?;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  robots.temp_init();

  while (try line = io::treadline(&input)) {
    robots.push(read_robot(line));
  }

  foreach (&robot: robots) {
    robot.move(100);
  }

  usz[2][2] quadrants = count_quadrants();
  
  usz result = 1;
  foreach (y, line: quadrants) {
    foreach (x, count: line) {
      result *= count;
    }
  }

  print_map();
  io::printfn("Safety factor 100 seconds: %d", result);

  if (try times = search_for_tree()) {
    io::printfn("Found tree? %d", times);
    print_map();
  } else {
    io::printfn("No tree found");
  }
}
