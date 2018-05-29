DOCKER_IMAGE=reprepro
DOCKER_NAMESPACE=nouchka

GPG_HOME="test/config"
TEST_DIST="jessie-dev"

.DEFAULT_GOAL := build

build:
	docker build -t $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE) .

check:
	docker run --rm -i hadolint/hadolint < Dockerfile 2>/dev/null; true

run:
	mkdir -p $(GPG_HOME)/
	chmod 700 -R ./test/config
	mkdir -p test/deb/$(TEST_DIST)/
	test -s test/deb/$(TEST_DIST)/hello.deb || wget -O test/deb/$(TEST_DIST)/hello.deb http://ftp.us.debian.org/debian/pool/main/h/hello/hello_2.10-1+b1_amd64.deb
	test -s $(GPG_HOME)/pubring.gpg || gpg --homedir=./$(GPG_HOME) --batch --gen-key test-gen-key
	##test -s $(GPG_HOME)/reprepro_pub.gpg || cp $(GPG_HOME)/pubring.gpg $(GPG_HOME)/reprepro_pub.gpg
	##test -s $(GPG_HOME)/reprepro_sec.gpg || cp $(GPG_HOME)/secring.gpg $(GPG_HOME)/reprepro_sec.gpg
	docker-compose up -d
	sleep 2
	docker ps
	wget -O- "http://localhost:88/repository.key" | sudo apt-key add -
	##TODO check if the right keys
	$(eval key=$(shell sh -c 'apt-key list|grep pub|tail -n1| sed "s/.*\/\([^ ]*\).*/\1/"'))
	sudo sh -c 'echo "deb [arch=amd64] http://localhost:88/repo $(TEST_DIST) main" > /etc/apt/sources.list.d/test.list'
	sudo apt-get update
	sudo apt-get install -yf hello
	hello
	sudo apt-get remove -yf hello
	sudo rm /etc/apt/sources.list.d/test.list
	sudo apt-key del $(key)

down:
	docker-compose down --volumes --remove-orphans
	test -s /etc/apt/sources.list.d/test.list || sudo rm /etc/apt/sources.list.d/test.list

test: build check run
