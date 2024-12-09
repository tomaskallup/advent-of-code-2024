import std::io;
import std::math;
import std::sort;
import std::collections::list;

def Row = int[];

List(<Row>) list;

fn bool validate_levels(int index, int left, int right, bool is_ascending, bool debug = false) {
  bool is_in_order = true;
  if (index > 1) {
    is_in_order = (!is_ascending && right < left) || (is_ascending && right > left);
  }
  usz distance = math::abs(right - left);

  if (debug) {
    io::printfn("[%d] %d: %s (%d) prev %d", index, right, is_in_order ? "in-order" : "not-in-order", distance, left);
  }

  return !is_in_order || (index > 0 && distance > 3 || distance < 1);
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;

  list.temp_init();

  List(<int>) current_row;
  current_row.temp_init();

  while (try line = io::treadline(&input)) {
    String[] splits = line.tsplit(" ");
    assert(splits.len > 2);

    foreach (item: splits) {
      current_row.push(item.to_int()!!);
    }

    list.push(current_row.to_tarray());
    current_row.clear();
  }

  usz safe = 0;
  usz safe_with_tolerance = 0;

  foreach (row_index, row: list) {
    bool is_safe = true;
    bool has_fault = false;
    bool is_ascending = true;
    int previous = 0;

    foreach (i, report: row) {
      if (i == 1) {
        if (report < previous) is_ascending = false;
      }

      bool is_faulty = validate_levels((int)i, previous, report, is_ascending, false);

      if (is_faulty) {
        if (has_fault) {
          is_safe = false;
          break;
        } else {
          has_fault = true;
        }
      }
      
      if (!is_faulty) { previous = report; }
      else {
        if (i < row.len-1) {
          int next = row[i+1];
          bool next_ascending = i == 2 ? next > report : is_ascending;
          bool next_is_faulty = validate_levels((int)(i+1), report, next, next_ascending, false);
          if (!next_is_faulty) previous = report;
        }
      }
    }

    if (is_safe) {
      safe_with_tolerance++;

      if (!has_fault) safe++;
    }
  }

  io::printfn("Safe: %d", safe);
  io::printfn("Safe with tolerance: %d", safe_with_tolerance);
}
