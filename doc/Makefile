SRCS := $(wildcard *.gv)
SVGS := $(SRCS:%.gv=%.svg)
PNGS := $(SRCS:%.gv=%.png)



doc: ${SVGS} ${PNGS}

all: doc

%.png: %.gv
	dot -Tpng $< >$@

%.svg: %.gv
	dot -Tsvg $< >$@


clean:
	rm -rf *.svg *.png
