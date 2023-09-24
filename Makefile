version := $(shell dpkg-parsechangelog | sed -n 's/^Version: //p' | cut -d- -f 1)

all: man/sya.1

%: %.md
		pandoc -s -t man -o $@ $<

smoketest:
		pwd > tests/conf/tobackup.include
		borg init -e none /tmp/local.borg
		./sya -d tests/conf

dist:
		git archive \
				--format=tar.gz HEAD . ":(exclude)debian" \
				--prefix=sya/ \
				-o ../sya_$(version).orig.tar.gz

clean:
		rm -f man/sya.1
		rm -f tests/conf/tobackup.include
