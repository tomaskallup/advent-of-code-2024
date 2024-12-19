import std::io;
import std::collections::list;
import std::collections::map;

String[] towels;
List(<String>) designs;

HashMap(<String, usz>) cache;

fn usz possible(String design) {
  if (!design.len) return 1;
  if (try cached = cache.get(design)) return cached;
  usz possibilities;
  String start = design;
  String end;

  while (start.len) {
    foreach (towel: towels) {
      if (start == towel) {
        possibilities += possible(end);
      }
    }

    end = design[start.len-1..];
    start = start[:^1];
  }

  cache.set(design, possibilities);

  return possibilities;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  designs.temp_init();
  cache.temp_init();

  towels = io::treadline(&input).tsplit(", ")!!;

  while (try line = io::treadline(&input)) {
    if (line == "") continue;
    designs.push(line);
  }
  
  usz result, count;
  foreach (design: designs) {
    usz design_possibilities = possible(design);
    if (design_possibilities) result++;
    count += design_possibilities;
  }

  io::printfn("Possible designs: %d", result);
  io::printfn("Ways to arrange desings: %d", count);
}
