import std::io;
import std::math;
import std::collections::list;
import std::collections::priorityqueue;

struct Registers {
  int a,b,c;
}

List(<char>) stack;
List(<char>) output;
Registers registers;
int instruction_pointer;

fn int combo_to_value(char operand) {
  switch (operand) {
    case 0: nextcase;
    case 1: nextcase;
    case 2: nextcase;
    case 3: return (int)operand;
    case 4: return registers.a;
    case 5: return registers.b;
    case 6: return registers.c;
    case 7: unreachable("Combo operand 7 should never happen");
  }

  unreachable("Operand is > 7");
}

fn int literal_to_value(char operand) @inline{
  return (int)operand;
}

fn void eval(char opcode, char operand) {
  switch (opcode) {
    case 0: // adv
      registers.a = registers.a >> combo_to_value(operand);
      instruction_pointer+=2;
    case 1: // bxl
      registers.b ^= literal_to_value(operand);
      instruction_pointer+=2;
    case 2: // bst
      registers.b = combo_to_value(operand)%8;
      instruction_pointer+=2;
    case 3: // jnz
      if (registers.a == 0) { instruction_pointer+=2; }
      else {
        instruction_pointer = literal_to_value(operand);
      }
    case 4: // bxc
      registers.b ^= registers.c;
      instruction_pointer+=2;
    case 5: // out
      output.push((char)(combo_to_value(operand)%8));
      instruction_pointer+=2;
    case 6: // bdv
      registers.b = registers.a >> combo_to_value(operand);
      instruction_pointer+=2;
    case 7: // cdv
      registers.c = registers.a >> combo_to_value(operand);
      instruction_pointer+=2;
  }
}

fn void run() {
  char opcode = stack[instruction_pointer];
  char operand = stack[(usz)instruction_pointer + 1];

  eval(opcode, operand);
}

fn int[] find_next(int a, char[] expected_output) {
  int[8] possibilities;
  usz found_count;
  // Each step of my program has `b = a%8` and everything after that
  // is dependend on value of `b`, so this step needs to be bruteforced
  // After that, a is divided by 2^3, which is just `a>>3`, so we reverse that and try every possible number from the modulo 8
  for (int i = 0; i < 8; i++) {
    int new_a = (a << 3) + i;
    registers = {
      new_a,
      0,
      0,
    };
    instruction_pointer = 0;
    output.clear();

    while (instruction_pointer < stack.len()) run();
    io::printfn("Comparing (%d) %s with %s", a, output.array_view(), expected_output);
    if (output.len() == expected_output.len && output.array_view() == expected_output) {
      possibilities[found_count++] = new_a;
    }
  }

  return possibilities[:found_count];
}

struct NextDepth {
  int a;
  usz output_index;
}

fn long NextDepth.compare_to(self, NextDepth other) {
  return other.output_index - self.output_index;
}

def Queue = PriorityQueue(<NextDepth>);

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");

  File input = file::open(args[1], "r")!!;
  
  bool parsing_registers = true;
  stack.temp_init();
  output.temp_init();

  while (try line = io::treadline(&input)) {
    if (line == "") {
      parsing_registers = false;
      continue;
    }
    String[] parts = line.tsplit(" ");
    if (parsing_registers) {
      int value = parts[2].to_int()!!;
      if (parts[1][0] == 'A') { registers.a = value; }
      else if (parts[1][0] == 'B') { registers.b = value; }
      else if (parts[1][0] == 'C') { registers.c = value; }
    } else {
      String[] instructions = parts[1].tsplit(",");
      foreach (instruction: instructions) {
        stack.push(instruction.to_uchar()!!);
      }
    }
  }

  io::printn(registers);
  io::printn(stack);

  while(instruction_pointer < stack.len()) {
    run();
  }

  foreach(index, ch: output) {
    if (index > 0) io::print(",");
    io::print(ch);
  }

  io::printn();

  /* Example program for reverse engineering:
  2,4
  // b = a%8 => 3
  1,5
  // b = b ^ 5 => 6
  7,5
  // c = a / math::pow(2, b) => 0
  0,3
  // a = a / math::pow(2, 3) => 0
  4,0
  // b = b ^ c => 6
  1,6
  // b = b ^ 6 => 0
  5,5
  // out(b) => 0
  3,0
  // if (a > 0) jmp(0);
   */

  output.clear();
  int! a = SearchResult.MISSING?;
  Queue queue;
  queue.temp_init();
  queue.push({ 0, stack.len() - 1 });
  
  while (try item = queue.pop()) {
    if (item.output_index == 0) {
      // This is BFS, so the first value should be the lowest one
      a = item.a;
      break;
    } else {
      long new_index = item.output_index;
      int[] new_items = find_next(item.a, stack.array_view()[new_index..]);
      foreach(new_item: new_items) queue.push({new_item, new_index - 1});
    }
  }

  if (catch a) {
    io::printn("Failed to find solution");
  } else {
    io::printfn("Found value needed for register A: %d", a);

    registers = {
      a,
      0,
      0,
    };
    instruction_pointer = 0;
    output.clear();
    while (instruction_pointer < stack.len()) {
      run();
    }

    foreach(index, ch: output) {
      if (index > 0) io::print(",");
      io::print(ch);
    }

    io::printn();
  }
}
