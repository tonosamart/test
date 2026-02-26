# Yakyuken - NES Rock Paper Scissors
# Requires: cc65 (ca65/ld65), python3

ROM = yakyuken.nes
OBJ = yakyuken.o
SRC = yakyuken.s
CHR = chr.bin
CFG = nes.cfg

.PHONY: all clean

all: $(ROM)

$(CHR): gen_chr.py
	python3 gen_chr.py

$(OBJ): $(SRC) $(CHR)
	ca65 $(SRC) -o $(OBJ)

$(ROM): $(OBJ) $(CFG)
	ld65 -C $(CFG) $(OBJ) -o $(ROM)

clean:
	rm -f $(OBJ) $(ROM) $(CHR)
