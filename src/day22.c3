import std::io;
import std::collections::list, std::collections::map;

List(<usz>) secrets;

union HashKey {
  ichar[4] sequence;
  uint h;
}

fn uint HashKey.hash(self) => self.h;
fn bool HashKey.equals(self, HashKey other) => self.h == other.h;

HashMap(<HashKey, usz>) result_cache;

fn usz get_next(usz secret, usz steps = 1) {
  usz result = secret;
  usz step;
  List(<ichar>) sequences;
  sequences.temp_init();
  defer sequences.free();
  HashMap(<HashKey, bool>) written_keys;
  written_keys.temp_init();
  defer written_keys.free();

  while (step++ < steps) {
    usz previous = result;
    // Multiply by 64, mix with XOR, prune
    result ^= result * 64;
    result %= 16777216;

    // Divide by 32, mix with XOR, prune
    result ^= result / 32;
    result %= 16777216;

    // Multiply by 64, mix with XOR, prune
    result ^= result * 2048;
    result %= 16777216;

    char previous_count = (char)(previous%10);
    char count = (char)(result%10);

    sequences.push((ichar)(count - previous_count));

    if (sequences.len() == 4) {
      HashKey key = {.sequence = sequences.array_view()[0:4]};
      if (!written_keys.has_key(key)) {
        result_cache.set(key, ((usz)result_cache.get(key) ?? 0) + count);
        written_keys.set(key, true);
      }
      sequences.pop_first()!!;
    }
  }

  return result;
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");
  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  secrets.temp_init();

  while (try line = io::treadline(&input)) secrets.push(line.to_long()!!);

  usz result;
  foreach(secret: secrets) {
    usz next = get_next(secret, 2000);
    result += next;
  }

  io::printfn("Sum of 2000th secret number: %d", result);

  usz best_count;
  HashKey best_key;

  result_cache.@each(;HashKey key, usz count) {
    if (count > best_count) {
      best_key = key;
      best_count = count;
    }
  };

  io::printfn("Best count %d with sequence %s", best_count, best_key.sequence);
}
