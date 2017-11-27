# Build command:
#
#     docker build . --no-cache --pull --tag asukakenji/fabric-golang:latest
#

FROM golang:latest

RUN apt-get -qq update \
		&& apt-get -qq --no-install-recommends install curl git libltdl-dev make

# The "make" step in fabric-sdk-go calls docker to clean up something non-existing.
# This is to fake the docker commands so that it passes.
RUN cd $GOPATH/bin \
		&& ln -s /bin/true docker \
		&& ln -s /bin/true docker-compose

# Originally, the fabric binaries (cryptogen, configtxgen, etc) should be built
# from the "fabric" Git repository using "make".
# However, that requires lots of dependencies.
# Therefore, the binaries are downloaded here for convenience.
#
# References:
#     http://hyperledger-fabric.readthedocs.io/en/release/samples.html
#
# Originally, to download the binaries, the following command should be used:
#
#     RUN curl -sSL https://goo.gl/5ftp2f | bash
#
# However, in the last step of the script,
# it checks the output of the "docker" commands (which is fake in this setting),
# and therefore fails.
#
# The essential part of the script is extracted and executed below:
#
RUN curl -sSL https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-1.0.4/hyperledger-fabric-linux-amd64-1.0.4.tar.gz | tar xz

RUN mkdir -p $GOPATH/src/github.com/hyperledger

RUN cd $GOPATH/src/github.com/hyperledger \
		&& git clone https://github.com/hyperledger/fabric.git \
		&& cd fabric \
		&& git checkout v1.0.4

RUN cd $GOPATH/src/github.com/hyperledger \
		&& git clone https://github.com/hyperledger/fabric-ca.git \
		&& cd fabric-ca \
		&& git checkout v1.0.4

RUN cd $GOPATH/src/github.com/hyperledger \
		&& git clone https://github.com/hyperledger/fabric-samples.git

RUN cd $GOPATH/src/github.com/hyperledger \
		&& git clone https://github.com/hyperledger/fabric-sdk-go.git \
		&& cd fabric-sdk-go \
		&& make depend-install \
		&& make

# Remove the fake commands
RUN rm -f $GOPATH/bin/docker $GOPATH/bin/docker-compose
