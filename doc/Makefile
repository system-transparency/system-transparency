SRCS := $(wildcard *.dot)
SVGS := $(SRCS:%.dot=%.svg)
PNGS := $(SRCS:%.dot=%.png)

doc: ${SVGS} ${PNGS}

all: doc

%.png: %.dot
	dot -Tpng $< >$@

%.svg: %.dot
	dot -Tsvg $< >$@

clean:
	rm -rf *.svg *.png

.PHONY: clean
