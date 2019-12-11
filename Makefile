DOCKER_IMAGE=reprepro

include Makefile.docker

GPG_HOME="test/config"
TEST_DIST="jessie-dev"
TEST_COMMAND="hello"
TEST_PACKAGE=$(TEST_COMMAND)

.DEFAULT_GOAL := build

deb:
	mkdir -p test/deb/$(TEST_DIST)/
	test -s test/deb/$(TEST_DIST)/hello.deb || wget -O test/deb/$(TEST_DIST)/hello.deb http://ftp.us.debian.org/debian/pool/main/h/hello/hello_2.10-1+b1_amd64.deb

run: deb
	mkdir -p $(GPG_HOME)/
	chmod 700 -R $(GPG_HOME)
	test -s $(GPG_HOME)/pubring.gpg || gpg --homedir=./$(GPG_HOME) --batch --gen-key test-gen-key
	docker-compose up -d
	sleep 2
	docker ps
	wget -O- "http://localhost:88/repository.key" | sudo apt-key add -
	##TODO check if the right keys
	$(eval key=$(shell sh -c 'apt-key list|grep pub|tail -n1| sed "s/.*\/\([^ ]*\).*/\1/"'))
	sudo sh -c 'echo "deb [arch=amd64] http://localhost:88/repo $(TEST_DIST) main" > /etc/apt/sources.list.d/test.list'
	sudo apt-get update
	sudo apt-get install -yf $(TEST_PACKAGE)
	$(TEST_COMMAND)
	sudo apt-get remove -yf $(TEST_PACKAGE)
	sudo rm /etc/apt/sources.list.d/test.list
	sudo apt-key del $(key)

down:
	docker-compose down --volumes --remove-orphans
	test ! -f /etc/apt/sources.list.d/test.list || sudo rm /etc/apt/sources.list.d/test.list

test: build hadolint run
