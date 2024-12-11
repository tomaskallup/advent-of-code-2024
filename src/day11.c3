import std::io;
import std::collections::list;
import std::collections::map;
import std::math;

List(<long>) inital_stones;
// Blink count -> stone count
def InnerMemo = HashMap(<long, long>);
// Stone number -> InnerMemo
HashMap(<long, InnerMemo*>) memo;

fn usz blink(long[] stones, uint times = 1) {
  usz count;
  if (times == 0) return 1;

  foreach (stone: stones) {
    InnerMemo* cache = memo.@get_or_set(stone, {|
      InnerMemo* new = mem::temp_new(InnerMemo);
      new.temp_init();
      return new;
    |});
    if (try cache_result = cache.get(times)) return cache_result;
    usz stone_count;

    if (stone == 0) {
      stone_count += blink({ 1 }, times - 1);
    } else {
      String st = string::tformat("%d", stone);
      if (st.len % 2 == 0) {
        long left_digits = st[0:st.len/2].to_long()!!;
        long right_digits = st[st.len/2..].to_long()!!;
        stone_count += blink({ left_digits }, times - 1);
        stone_count += blink({ right_digits }, times - 1);
      } else {
        stone_count += blink({ stone * 2024 }, times - 1);
      }
    }

    cache.set(times, stone_count);

    count += stone_count;
  }

  return count;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  inital_stones.temp_init();

  if (try line = io::readline(&input)) {
    String[] nums = line.tsplit(" ");
    foreach (raw_num: nums) {
      inital_stones.push(raw_num.to_long()!!);
    }
  } else {
    unreachable("Input was empty");
  }

  io::printfn("Stones after 25 blinks: %d", blink(inital_stones.array_view(), 25));
  io::printfn("Stones after 75 blinks: %d", blink(inital_stones.array_view(), 75));
}
