SYA_EXECUTABLE ?= ./sya

all: man/sya.1

%: %.md
		pandoc -s -t man -o $@ $<

smoketest:
		pwd > tests/conf/tobackup.include
		borg init -e none /tmp/local.borg
		$(SYA_EXECUTABLE) -d tests/conf

clean:
		rm -f man/sya.1
		rm -f tests/conf/tobackup.include
