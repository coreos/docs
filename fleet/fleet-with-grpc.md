# Fleet with gRPC

To build fleet with gRPC enabled, first of all, you need to install several
protobuf compilers.

## Install protobuf packages

Install a native protobuf compiler. Any version should work, but v3.0 or higher is recommended.
For details, refer to [protobuf documentation](https://developers.google.com/protocol-buffers/).

```
$ wget https://github.com/google/protobuf/releases/download/v3.0.0-beta-3/protobuf-cpp-3.0.0-beta-3.tar.gz
$ tar xzf protobuf-cpp-3.0.0-beta-3.tar.gz
$ cd protobuf-3.0.0-beta-3
$ ./configure --prefix=$HOME
$ make
$ make install prefix=$HOME
$ ls $HOME/bin/protoc
/home/.../bin/protoc*
```

## Install required go protobuf packages.

In addition, you need to install protobuf support for golang, not only official
protoc-gen-go, but also protoc-gen-gogo from the 3rd-party repo gogo/protobuf.

```
$ go get -u github.com/golang/protobuf/proto
$ go get -u github.com/golang/protobuf/protoc-gen-go
$ go get -u github.com/gogo/protobuf/proto
$ go get -u github.com/gogo/protobuf/protoc-gen-gogo
$ go get -u github.com/gogo/protobuf/gogoproto
```

If the gogo/protobuf above doesn't work as expected, install a specific commit c3995ae43 ("one build server") of gogo/protobuf. (As of 2016-06-09)

```
$ git clone https://github.com/gogo/protobuf
$ cd protobuf
$ git checkout -b c3995ae4 c3995ae4
$ make install
```

## Convert *.proto to *.pb.go

Now you need to clone git repo of fleet, to check out a specific branch to enable gRPC.

```
$ go get -u github.com/endocode/fleet
$ cd $GOPATH/src/github.com/endocode/fleet
$ git checkout -b dongsu/grpc_engine_communication origin/dongsu/grpc_engine_communication
### (or any possible branch for gRPC)
```

If necessary, you need to regenerate from fleet.proto to fleet.pb.go.

```
$ cd protobuf
$ protoc --proto_path=$GOPATH/src:. --gogofaster_out=plugins=grpc:. ./fleet.proto
$ ls
fleet.pb.go   fleet.proto
```

Or you can also make use of a script provided by fleet, *scripts/genproto.sh*.

```
$ ./scripts/genproto.sh
```
