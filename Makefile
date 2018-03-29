program = pinglist

build: bin
	crystal build src/$(program).cr -o ./bin/$(program)

bin:
	mkdir bin


debug: build
	./bin/$(program)

release: bin
	crystal build src/$(program).cr -o ./bin/$(program)-release --release --static



