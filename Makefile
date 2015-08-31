SHELL := $(shell echo $$SHELL)

ROCKS_BRANCH := "mongorocks"
MONGO_BRANCH := "v3.0.5-mongorocks"
MONGOTOOLS_BRANCH := "v3.0"

TARNAME := "mongodb-linux-x86_64-${VERSION}"
DEST := "rpm/${TARNAME}"

clean:
	rm -rf rpm mongo rocksdb mongo-tools

dependencies:
	sudo yum -y install snappy-devel zlib-devel bzip2-devel createrepo cyrus-sasl-devel openssl-devel

install-scons:
	test -x "/usr/bin/scons" || sudo rpm -Uvh "http://downloads.sourceforge.net/project/scons/scons/2.3.6/scons-2.3.6-1.noarch.rpm?r=http%3A%2F%2Fwww.scons.org%2Fdownload.php&ts=1440779277&use_mirror=freefr"

clone-rocks:
	test -d "rocksdb" || git clone https://github.com/facebook/rocksdb.git
	cd rocksdb; git checkout ${ROCKS_BRANCH}

clone-mongodb:
	test -d "mongo" || git clone https://github.com/mongodb-partners/mongo.git
	cd mongo; git checkout ${MONGO_BRANCH}

clone-mongotools:
	test -d "mongo-tools" || git clone https://github.com/mongodb/mongo-tools
	cd mongo-tools; git checkout ${MONGOROCKS_BRANCH}

build-rocks: 
	cd rocksdb; USE_SSE=1 make static_lib

build-mongodb: 
	cd mongo; scons --rocksdb=1 mongod mongo mongos mongoperf

build-mongotools:
	cd mongo-tools; ./build.sh "ssl sasl"

install-rocks: 
	cd rocksdb; sudo make install

tarball:
	test ! -z "${VERSION}" || exit 123
	mkdir -p ${DEST}/bin
	cp mongo/mongo mongo/mongos mongo/mongod mongo/mongoperf ${DEST}/bin
	cp mongo/README mongo/distsrc/THIRD-PARTY-NOTICES ${DEST}
	cp mongo/GNU-AGPL-3.0.txt ${DEST}/GNU-AGPL-3.0
	cp mongo-tools/bin/* ${DEST}/bin
	cd rpm; tar -cvzf mongo-binary.tar.gz ${TARNAME}

rpm:
	cd mongo/buildscripts; ./packager.py -s ${VERSION}-rocks  -m `git rev-parse HEAD` -r 1 -d rhel70 -t `realpath ../../rpm/mongo-binary.tar.gz `


all: clean dependencies install-scons clone-rocks clone-mongodb clone-mongotools build-rocks install-rocks build-mongotools build-mongodb tarball rpm