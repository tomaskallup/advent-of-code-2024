import std::io;
import std::math;
import std::sort;
import std::collections::list;

List(<int>) list1;
List(<int>) list2;

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  while (try line = io::treadline(&input)) {
    String[] splits = line.tsplit("   ");
    assert(splits.len == 2);
    list1.push(splits[0].to_int()!!);
    list2.push(splits[1].to_int()!!);
  }

  io::printfn("%d %d", list1.size, list2.size);

  usz distance = 0;
  usz similarity = 0;
  usz similarity_multiplier = 0;
  usz last_id = 0;

  quicksort(list1, fn long (int a, int b) => (long)a-b);
  quicksort(list2, fn long (int a, int b) => (long)a-b);

  for (usz i = 0; i < list1.size; i++) {
    int left_val = list1[i];
    if (i == 0 || last_id != left_val) {
      similarity_multiplier = 0;
      foreach (v : list2)
      {
        if (v > left_val) break;
        if (v == left_val) similarity_multiplier++;
      }
    }

    last_id = left_val;

    similarity += left_val * similarity_multiplier;

    distance += math::abs(list2[i] - left_val);
  }

  io::printfn("Distance: %d", distance);
  io::printfn("Similarity: %d", similarity);
}
