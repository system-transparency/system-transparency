all: doc

doc: st-map.png

%.png: %.gv
	dot -Tpng $< >$@
