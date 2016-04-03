SHELL := $(shell echo $$SHELL)
VERSION := "3.2.4"
ROCKS_BRANCH := "4.4.fb"
MONGO_BRANCH := "r${VERSION}"
MONGOTOOLS_BRANCH := "v3.2"
RELEASE_VER := "2"
BUILD_HOME := "/home/vagrant/build"

TARNAME := "mongodb-linux-x86_64-${VERSION}"
DEST := "${BUILD_HOME}/rpm/${TARNAME}"

clean:
	rm -rf ${BUILD_HOME}

setup:
	mkdir -p ${BUILD_HOME}

clone-rocks: setup
	test -d "${BUILD_HOME}/rocksdb" || git clone https://github.com/facebook/rocksdb.git ${BUILD_HOME}/rocksdb
	cd ${BUILD_HOME}/rocksdb; git checkout ${ROCKS_BRANCH}; cd ..

clone-mongodb: setup
	test -d "${BUILD_HOME}/mongo" || git clone https://github.com/mongodb/mongo.git ${BUILD_HOME}/mongo
	cd ${BUILD_HOME}/mongo; git checkout ${MONGO_BRANCH}; cd ..

clone-mongorocks: setup clone-mongodb
	test -d "${BUILD_HOME}/mongo-rocks" || git clone https://github.com/mongodb-partners/mongo-rocks.git ${BUILD_HOME}/mongo-rocks
	cd ${BUILD_HOME}/mongo-rocks; git checkout ${MONGO_BRANCH}; cd ..
	cd ${BUILD_HOME}/mongo; mkdir -p src/mongo/db/modules/; ln -sf ${BUILD_HOME}/mongo-rocks src/mongo/db/modules/rocks; cd ..

clone-mongotools: setup clone-mongodb
	test -d "${BUILD_HOME}/mongo-tools" || git clone https://github.com/mongodb/mongo-tools ${BUILD_HOME}/mongo-tools
	cd ${BUILD_HOME}/mongo-tools; git checkout ${MONGOTOOLS_BRANCH}; cd ..

build-rocks: clone-rocks
	cd ${BUILD_HOME}/rocksdb; USE_SSE=1 make static_lib; cd ..

build-mongodb: build-rocks clone-mongodb clone-mongorocks
	cd ${BUILD_HOME}/mongo; scons CPPPATH=${BUILD_HOME}/rocksdb/include LIBPATH=${BUILD_HOME}/rocksdb LIBS=lz4 -j 4 mongod mongo mongos mongoperf; cd ..

build-mongotools: clone-mongotools
	cd ${BUILD_HOME}/mongo-tools; ./build.sh "ssl sasl"; cd ..

# install-rocks: build-rocks
#	cd ${BUILD_HOME}/rocksdb; sudo make install; cd ..

tarball: build-mongodb build-mongotools
	test ! -z "${VERSION}" || exit 123
	mkdir -p ${DEST}/bin
	cp ${BUILD_HOME}/mongo/mongo ${BUILD_HOME}/mongo/mongos ${BUILD_HOME}/mongo/mongod ${BUILD_HOME}/mongo/mongoperf ${DEST}/bin
	cp ${BUILD_HOME}/mongo/README ${BUILD_HOME}/mongo/distsrc/THIRD-PARTY-NOTICES ${BUILD_HOME}/mongo/distsrc/MPL-2 ${DEST}
	cp ${BUILD_HOME}/mongo/GNU-AGPL-3.0.txt ${DEST}/GNU-AGPL-3.0
	cp ${BUILD_HOME}/mongo-tools/bin/* ${DEST}/bin
	cd ${BUILD_HOME}/rpm; tar -cvzf ${BUILD_HOME}/mongo-binary.tar.gz ${TARNAME}

package: tarball
	cd ${BUILD_HOME}/mongo/buildscripts; ./packager.py -s ${VERSION}.rocks  -m `git rev-parse HEAD` -r ${RELEASE_VER} -d rhel70 -t ${BUILD_HOME}/mongo-binary.tar.gz

all: clean setup package
