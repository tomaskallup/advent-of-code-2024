import std::io;
import std::collections::list;

const EMPTY_VAL = -1;

fn usz calculate_checksum(long[] file_system) {
  usz checksum;

  foreach (i, val: file_system) {
    if (val == EMPTY_VAL) continue;
    checksum += i * val;
  }

  return checksum;
}

fn void fragmentation(long[] file_system) {
  usz index = 0;
  usz last_index = file_system.len - 1;

  while (index++ < last_index) {
    if (file_system[index] == EMPTY_VAL) {
      while (file_system[last_index] == EMPTY_VAL && index < last_index) last_index--;
      if (index == last_index) break;

      file_system[index] = file_system[last_index];
      file_system[last_index] = EMPTY_VAL;
    }
  }

  io::printfn("Checksum fragmentation: %d", calculate_checksum(file_system));
}

fn usz! find_gap(long[] file_system, usz length) {
  /* io::printfn("Looking for gap: %d", length);
  io::printn(file_system); */
  usz start_index;
  for (usz index = 0;index < file_system.len-1;index++) {
    if (file_system[index] != EMPTY_VAL || file_system[start_index] != EMPTY_VAL) {
      start_index = index;
    }

    if (file_system[index] == EMPTY_VAL) {
      // io::printfn("Index %d, start_index %d, size %d", index, start_index, (index - start_index));

      if ((1 + index - start_index) == length) return start_index;
    }
  }

  return SearchResult.MISSING?;
}

fn void moving(long[] file_system) {
  for(usz index = file_system.len - 1;; index--) {
    long id = file_system[index];
    if (id == EMPTY_VAL) continue;

    usz start_index = index;
    defer index = start_index;

    while (start_index > 0 && file_system[start_index-1] == id) start_index--;
    if (start_index == 0) break;

    usz lenght = 1 + index - start_index;

    if (try gap_index = find_gap(file_system, lenght)) {
      if (gap_index > start_index) continue;

      file_system[gap_index:lenght] = file_system[start_index:lenght];
      file_system[start_index:lenght] = EMPTY_VAL;
    }
  }

  io::printfn("Checksum moving: %d", calculate_checksum(file_system));
}

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  List(<long>) file_system;
  file_system.temp_init();

  usz type, id;
  while (try ch = input.read_byte() - '0') {
    // The file ends with newline, the - '0' causes an underflow, this way we skip it
    if (ch > '9') break;

    usz val = EMPTY_VAL;
    if (type++ % 2 == 0) {
      val = id++;
    }

    while (ch-- > 0) file_system.push(val);
  }

  fragmentation(file_system.to_tarray());
  moving(file_system.to_tarray());
}
