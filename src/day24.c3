import std::io;
import std::collections::list, std::collections::map;
import std::sort, std::math;

struct Connection (Printable) {
  String[2] inputs;
  String output;
  String operator;
}

fn bool String[2].contains(self, String needle) {
  foreach(item: self) {
    if (item == needle) return true;
  }

  return false;
}

fn usz! Connection.to_format(&self, Formatter* f) @dynamic
{
	return f.printf("%s %s %s -> %s", self.inputs[0], self.operator, self.inputs[1], self.output);
}

fn int String.compare_to(self, String other) {
  usz max_len = math::max(self.len, other.len);
  for (usz index; index < max_len; index++) { 
    if (index >= other.len) return 1;
    if (index >= self.len) return -1;

    int diff = self[index] - other[index];
    if (diff != 0) return diff;
  }

  return 0;
}

fn String get_carry_bit_layout(usz level) {
  if (level == 0) return "x00 AND y00";

  return string::tformat("(%s AND (x%02d XOR y%02d)) OR (x%02d AND y%02d)", get_carry_bit_layout(level - 1), level, level, level, level);
}

fn String get_expected_output_layout(usz level) {
  if (level == 0) return "x00 XOR y00";

  return string::tformat("(%s) XOR (x%02d XOR y%02d)", get_carry_bit_layout(level - 1), level, level);
}

<*
  Checks if an output wire is corretly wired to its inputs.
  Specifically, it should have a XOR gate, which should combine a XOR of relevant inputs & previous carry bit
*>
fn String check_wire(String wire) {
  Connection connection = output_mapping.get(wire)!!;

  if (connection.operator != "XOR") return wire;

  if (wire == "z00") {
    if (!connection.inputs.contains("x00") || !connection.inputs.contains("y00")) return wire;

    // This one is correct, no carry bit check needed
    return "";
  }

  String input_x = string::tformat("x%s", wire[1..]);
  String input_y = string::tformat("y%s", wire[1..]);

  foreach (char index, input: connection.inputs) {
    // The input should not be x or y input directly, they need to be XORed
    if (input[0] == 'x' || input[0] == 'y') return wire;

    Connection next_connection = output_mapping.get(input)!!;

    // Next should be a XOR for x & y
    // Or an OR for the carry bit (or an AND for the first carry bit)
    if (next_connection.operator == "XOR") {
      if (!next_connection.inputs.contains(input_x) || !next_connection.inputs.contains(input_y)) return input;
    } else if (next_connection.operator == "OR") {
      // Carry bit 2 and up is alwas:
      // (Previous carry AND (x XOR y)) OR (x AND y)
      // So we only check if we have an OR with AND on each side, since only outputs are swapped, this should suffice
      Connection left_part = output_mapping.get(next_connection.inputs[0])!!;
      Connection right_part = output_mapping.get(next_connection.inputs[1])!!;

      if (left_part.operator != "AND") return left_part.output;
      if (right_part.operator != "AND") return right_part.output;
    } else if (next_connection.operator == "AND" && wire == "z01") {
      // Special case for the first carry bit
      if (!next_connection.inputs.contains("x00") || !next_connection.inputs.contains("y00")) return input;
    } else {
      return next_connection.output;
    }
  }

  return "";
}

def Wires = HashMap(<String, bool>);
Wires wires;
List(<Connection>) connections;
List(<String>) output_wires;
HashMap(<String, Connection>) output_mapping;

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");
  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  wires.temp_init();
  connections.temp_init();
  output_wires.temp_init();
  output_mapping.temp_init();

  bool parsing_wires = true;

  while (try line = io::treadline(&input)) {
    if (parsing_wires) {
      if (line == "") {
        parsing_wires = false;
        continue;
      }

      String[] parts = line.tsplit(": ");

      wires.set(parts[0], parts[1] == "1");
    } else {
      String[] parts = line.tsplit(" ");
      Connection connection = {
        .inputs = {parts[0],parts[2]},
        .output = parts[4],
        .operator = parts[1],
      };
      connections.push(connection);
      output_mapping.set(connection.output, connection);

      if (connection.output[0] == 'z') output_wires.push(connection.output);
    }
  }

  sort::quicksort(output_wires);

  List(<Connection>) queue;
  queue.temp_init_with_array(connections.array_view());

  while (try connection = queue.pop_first()) {
    bool! input1 = wires.get(connection.inputs[0]);
    bool! input2 = wires.get(connection.inputs[1]);

    // Inputs are not ready, push to the end
    if (catch input1, input2) {
      queue.push(connection);
      continue;
    }

    bool result;
    switch (connection.operator) {
      case "AND": result = input1 & input2;
      case "OR": result = input1 | input2;
      case "XOR": result = input1 ^ input2;
    }

    wires.set(connection.output, result);
  }

  List(<String>) invalid_outputs;
  invalid_outputs.temp_init();

  usz result, expected_result, x_num, y_num;
  foreach(index, output_wire: output_wires) {
    bool output = wires.get(output_wire)!!;
    result += (usz)output << index;

    String input_x = string::tformat("x%s", output_wire[1..]);
    String input_y = string::tformat("y%s", output_wire[1..]);

    // The last output is just the last carry bit, so it has no direct x&y inputs
    if (index < output_wires.len() - 1) {
      bool x_output = wires.get(input_x)!!;
      bool y_output = wires.get(input_y)!!;
      usz x_result = (usz)x_output << index;
      usz y_result = (usz)y_output << index;
      x_num += x_result;
      y_num += y_result;
      expected_result += x_result + y_result;
    }
    bool expected_output = (bool)((expected_result >> index) & 1);

    if (output ^ expected_output) {
      invalid_outputs.push(output_wire);
    }
  }

  io::printn("Input numbers:");
  io::printfn("x: %d (%b)", x_num, x_num);
  io::printfn("y: %d (%b)", y_num, y_num);
  io::printfn("Result number from binary (part1 answer):\n%d (%b)", result, result);
  io::printfn("%d (%b)", expected_result, expected_result);
  io::printn("^ Expected number for correct addition");

  List(<String>) swaps;
  swaps.temp_init();

  foreach (invalid_output: invalid_outputs) {
    String check_result = check_wire(invalid_output);

    if (check_result != "") swaps.push(check_result);
  }

  sort::quicksort(swaps);

  io::print("Swapped wires, sorted alphabetically: ");

  foreach (index, swap: swaps) {
    if (index > 0) io::print(",");
    io::print(swap);
  }

  io::printn();
}
