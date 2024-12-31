import std::io;
import std::collections::list, std::collections::map;
import std::sort, std::math;

struct Connection (Printable) {
  String[2] inputs;
  String output;
  String operator;
}

fn usz! Connection.to_format(&self, Formatter* f) @dynamic
{
	return f.printf("%s %s %s -> %s", self.inputs[0], self.operator, self.inputs[1], self.output);
}

HashMap(<String, bool>) wires;
List(<Connection>) connections;
List(<String>) output_wires;

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

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");
  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  wires.temp_init();
  connections.temp_init();
  output_wires.temp_init();

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
      connections.push({
        .inputs = {parts[0],parts[2]},
        .output = parts[4],
        .operator = parts[1],
      });
      if (parts[4][0] == 'z' && !output_wires.contains(parts[4])) output_wires.push(parts[4]);
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

  usz result;
  foreach(index, output_wire: output_wires) {
    result += (usz)wires.get(output_wire)!! << index;
  }
  io::printfn("Result: %d", result);
}
