SHELL := $(shell echo $$SHELL)

ROCKS_BRANCH := "v4.1"
MONGO_BRANCH := "v3.0.7-mongorocks"
MONGOTOOLS_BRANCH := "v3.0"
RELEASE_VER := "2"

TARNAME := "mongodb-linux-x86_64-${VERSION}"
DEST := "rpm/${TARNAME}"

clean:
	rm -rf rpm mongo rocksdb mongo-tools

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
	cd mongo; scons -j 2 --rocksdb=1 mongod mongo mongos mongoperf

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

package:
	cd mongo/buildscripts; ./packager.py -s ${VERSION}-rocks  -m `git rev-parse HEAD` -r ${RELEASE_VER} -d rhel70 -t `realpath ../../rpm/mongo-binary.tar.gz `


all: clean clone-rocks clone-mongodb clone-mongotools build-rocks install-rocks build-mongotools build-mongodb tarball package
