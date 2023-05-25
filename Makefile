version := $(shell dpkg-parsechangelog | sed -n 's/^Version: //p' | cut -d- -f 1)

all: man/sya.1

%: %.md
		pandoc -s -t man -o $@ $<

dist:
		git archive \
				--format=tar.gz HEAD . ":(exclude)debian" \
				--prefix=sya/ \
				-o ../sya_$(version).orig.tar.gz

clean:
		rm -f man/sya.1
