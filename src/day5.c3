import std::io;
import std::collections::list;
import std::collections::map;
import std::sort;


def NumsAfter = List(<String>)*;
HashMap(<String, NumsAfter>) ordering;

fn int update_compare_fn(String a, String b) {
  if (a == b) return 0;

  if (try NumsAfter numbers_after_a = ordering.get(a)) {
    foreach(number_after_a: numbers_after_a) {
      if (number_after_a == b) return -1;
    }
  }

  if (try NumsAfter numbers_after_b = ordering.get(b)) {
    foreach(number_after_b: numbers_after_b) {
      if (number_after_b == a) return 1;
    }
  }

  return 0;
}

fn void main (String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  ordering.temp_init();

  usz result = 0;
  usz result_invalid = 0;

  // Get rules
  while (try rule_line = io::treadline(&input)) {
    if (rule_line.len == 0) break;
    String[] split = rule_line.tsplit("|");
    assert(split.len == 2, "Line %s failed", rule_line);
    String key = split[0];
    String value = split[1];
    NumsAfter values = ordering.@get_or_set(key, mem::temp_new(List(<String>)));
    if (!values.allocator) values.temp_init();
    values.push(value);
  }

  usz index = 0;
  // Check updates
  while (try update = io::treadline(&input)) {
    String[] numbers = update.tsplit(",");
    bool valid = true;

    foreach NUM: (i, number: numbers) {
      String[] numbers_before = numbers[0:i];
      String[] numbers_after = numbers[i+1..];

      /* io::printfn("%d: %s", i, number);
      io::printn(numbers_before);
      io::printn(numbers_after); */
      if (try NumsAfter order_numbers = ordering.get(number)) {
        foreach(order_number: order_numbers) {
          foreach(number_before: numbers_before) {
            if (order_number == number_before) {
              valid = false;
              break NUM;
            }
          }
        }
        /* io::printn(order_numbers); */
      } else {
        /* io::printn("No rules"); */
      }
    }

    usz middle = numbers.len / 2;

    if (valid) {
      result += numbers[middle].to_int()!!;
    } else {
      quicksort(numbers, &update_compare_fn);

      result_invalid += numbers[middle].to_int()!!;
    }
    
    index++;
  }

  io::printfn("Result: %d", result);
  io::printfn("Result for invalid: %d", result_invalid);
}
