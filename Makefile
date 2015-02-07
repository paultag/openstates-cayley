STATES = al ak az ar ca co ct de dc fl ga hi id il in ia ks ky la me md ma mi \
		 mn ms mo mt ne nv nh nj nm ny nc nd oh ok or pa ri sc sd tn tx ut vt \
		 va wa wv wi wy

tripples: $(STATES)
	cat $(STATES) > tripples


$(STATES):
	python3 ferruginous.py > $@

clean:
	rm -rvf $(STATES) tripples

all: tripples

.PHONY: clean all
