

build: bin
	crystal build src/pinglist.cr -o ./bin/pinglist

bin:
	mkdir bin


debug: build
	./bin/pinglist -i test.txt -o result.txt