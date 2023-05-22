all: doc

doc: stboot.png

%.png: %.gv
	dot -Tpng $< >$@
