import std::io;
import std::collections::list, std::collections::map;
import std::sort;

union Computer {
  char[2] identifier;
  ushort h;
}

fn char Computer.get(self, usz index) @operator([]) => self.identifier[index];
fn uint Computer.hash(self) => self.h;
fn bool Computer.equals(self, Computer other) => self.h == other.h;
fn int Computer.compare_to(self, Computer other) {
  if (self[0] != other[0]) return self[0] - other[0];

  return self[1] - other[1];
}
fn usz! Computer.to_format(&self, Formatter* f) @dynamic
{
	return f.printf("%c%c", ...self.identifier);
}

def Links = List(<Computer>);
def Computers = HashMap(<Computer, Links>);

fn void Computers.append_link(&self, Computer computer, Computer linked_computer) {
  Links links = self.get(computer) ?? *Links{}.temp_init();

  links.push(linked_computer);
  self.set(computer, links);
}

def Network = Computer[];
fn usz! Network.to_format(&self, Formatter* formatter) @dynamic
{
	switch (self.len)
	{
		case 0:
			return formatter.print("")!;
		case 1:
			return formatter.printf("%s", self[0])!;
		default:
			usz n;
			foreach (i, element : self)
			{
				if (i != 0) formatter.print(",")!;
				n += formatter.printf("%s", element)!;
			}
			return n;
	}
}

fn Network Computers.find_largest_network(self) {
  List(<Computer>) largest;
  self.@each(;Computer computer, Links links) {
    // Skip computers which have less links than current largest network
    if (largest.len() < links.len()) {
      List(<Computer>) network;
      network.temp_init_with_array(links.array_view());
      network.push_front(computer);
      for (usz index; index < network.len() - 1; index++) {
        Computer network_computer = network[index];
        Links computer_links = self.get(network_computer)!!;
        foreach_r (next_computer: network.array_view()[index+1..]) {
          if (!computer_links.contains(next_computer)) network.remove_item(next_computer);
        }
      }

      if (network.len() > largest.len()) largest = network;
    }
  };

  sort::quicksort(largest);
  return largest.array_view();
}

Computers computers;

fn void main(String[] args) {
  assert(args.len == 2, "Expected exactly 1 argument: the input file");
  File input = file::open(args[1], "r")!!;
  defer input.close()!!;

  computers.temp_init();

  while (try line = io::treadline(&input)) {
    String[] linked_computers = line.tsplit("-");

    Computer first = {linked_computers[0][0:2]};
    Computer second = {linked_computers[1][0:2]};

    computers.append_link(first, second);
    computers.append_link(second, first);
  }

  List(<String>) visited;
  visited.temp_init();

  usz count;
  computers.@each(;Computer computer, Links links) {
    foreach (index, link: links) {
      foreach (next_link: links.array_view()[index+1..]) {
        Links links_to_check = computers.get(link)!!;

        if (!links_to_check.contains(next_link)) continue;

        if (computer.identifier[0] != 't' && link.identifier[0] != 't' && next_link.identifier[0] != 't') continue;

        Network network = {computer, link, next_link};
        sort::quicksort(network);
        String key = string::tformat("%s", network);
        if (visited.contains(key)) continue;
        visited.push(key);
        count++;
      }
    }
  };

  io::printfn("Count of 3 computer networks with 't': %d", count);
  io::printfn("Largest network: %s", computers.find_largest_network());
}
