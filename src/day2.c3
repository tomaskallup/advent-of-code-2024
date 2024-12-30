import std::io;
import std::math;
import std::sort;
import std::collections::list;

def Row = int[];

List(<Row>) list;

fn int validate_row(Row row) {
  bool ascending = row[0] < row[1];
  foreach (int index, report: row) {
    if (index < row.len - 1) {
      int next = row[index+1];

      if (ascending && report > next) { return index; }
      else if (!ascending && report < next) { return index; }
      uint distance = math::abs(report - next);
      if (distance > 3 || distance < 1) return index;
    }
  }

  return -1;
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

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

  foreach (row: list) {
    int first_result = validate_row(row);
    if (first_result == -1) {
      safe++;
      safe_with_tolerance++;
    } else {
      Row new_row = mem::temp_new_array(int, row.len - 1);
      if (first_result) {
        new_row[0:first_result] = row[0:first_result];
      }
      new_row[first_result..] = row[first_result+1..];

      bool safe_without_one = validate_row(new_row) == -1;
      // Try without the next element
      if (!safe_without_one) {
        new_row[first_result] = row[first_result];

        safe_without_one = validate_row(new_row) == -1;
      };
      // Try without the first element, if second one fails
      if (!safe_without_one && first_result == 1) {
        new_row[0..] = row[1..];

        safe_without_one = validate_row(new_row) == -1;
      };

      if (safe_without_one) {
        safe_with_tolerance++;
      }
    }
  }

  io::printfn("Safe: %d", safe);
  io::printfn("Safe with tolerance: %d", safe_with_tolerance);
}
