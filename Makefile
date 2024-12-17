BIN_PATH := bin
SRC_PATH := src
INP_PATH := inputs

DAY := 1
DAY_NAME = day$(DAY)
DAY_SRC = src/$(DAY_NAME).c3
DAY_BIN = bin/$(DAY_NAME)
DAY_INP = inputs/$(DAY_NAME).txt
DAY_INP_EX = inputs/$(DAY_NAME)-example.txt

bin:
	mkdir bin

build: bin $(DAY_SRC)
	c3c compile $(DAY_SRC) -o $(DAY_BIN)

build-example: bin $(DAY_SRC)
	c3c compile -D EXAMPLE $(DAY_SRC) -o $(DAY_BIN)

run: build $(DAY_INP)
	./$(DAY_BIN) $(DAY_INP)

run-example: build-example $(DAY_INP_EX)
	./$(DAY_BIN) $(DAY_INP_EX)
