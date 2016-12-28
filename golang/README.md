# Go at CoreOS

We use Go (golang) a lot at CoreOS, and we’ve built up a lot of internal knowledge about how best to develop Go projects.

This document serves as a best practices and style guide for how to work on new and existing CoreOS projects written in Go.

## Version

- Wherever possible, use the [latest official release][go-dl] of go
- Any software shipped in the Container Linux image should be developed against the [versions shipped in the Container Linux image](https://github.com/coreos/coreos-overlay/tree/master/dev-lang/go)

[go-dl]: https://golang.org/dl/

## Style

Go style at CoreOS essentially just means following the upstream conventions:
  - [Effective Go][effectivego]
  - [CodeReviewComments][codereview]
  - [Godoc][godoc]

It's recommended to set a save hook in your editor of choice that runs `goimports` against your code.

[effectivego]: https://golang.org/doc/effective_go.html
[codereview]: https://github.com/golang/go/wiki/CodeReviewComments
[godoc]: http://blog.golang.org/godoc-documenting-go-code

## Tests

- Always run [goimports][goimports] (which transitively calls `gofmt`) and `go vet`
- Use [table-driven tests][table-driven] wherever possible ([example][table-driven-example])
- Use [travis][travis] to run unit/integration tests against the project repository ([example][travis-example])
- Use [SemaphoreCI][semaphore] to run functional tests where possible ([example][semaphore-example])
- Use [GoDebug][godebug] `pretty.Compare` to compare objects (structs, maps, slices, etc.)

[godebug]: https://github.com/kylelemons/godebug/
[goimports]: https://github.com/bradfitz/goimports
[table-driven]: https://github.com/golang/go/wiki/TableDrivenTests
[table-driven-example]: https://github.com/coreos/etcd/blob/35fddbc5d01f5e88bbc590c60f0b5e3ea8fa141b/raft/raft_paper_test.go#L186
[travis]: https://travis-ci.org/
[travis-example]: https://github.com/coreos/fleet/blob/master/.travis.yml
[semaphore]: https://semaphoreci.com/
[semaphore-example]: https://github.com/coreos/rkt/blob/master/tests/README.md

## Dependencies

- Carefully consider adding dependencies to your project: Do you really need it?
- Manage third-party dependencies with [Glide][glide] and [glide-vc][glide-vc].

[glide]: https://github.com/Masterminds/glide
[glide-vc]: https://github.com/sgotti/glide-vc

## Shared Code

Idiomatic golang generally eschews creating generic utility packages in favour of implementing the necessary code as locally as possible to its use case.
In cases where generic, utility code makes sense, though, move it to `github.com/coreos/pkg`.
Use this repository as a first port of call when the need for generic code seems to arise.

## Docker

When creating Docker images from Go projects, use a combination of a `.godir` file and the `golang:onbuild` base image to produce the most simple Dockerfile for a Go project.
The `.godir` file must contain the import path of the package being written (i.e. etcd's .godir contains "github.com/coreos/etcd").

## Logging

When in need of more sophisticated logging than the [stdlib log package][stdlib-log] provides, use the shared [CoreOS Log package][capnslog] (aka `capnslog`)

[stdlib-log]: https://golang.org/pkg/log
[capnslog]: https://github.com/coreos/pkg/tree/master/capnslog

## CLI

In anything other than the most basic CLI cases (i.e. where the [stdlib flag package][stdlib-flag] suffices), use [Cobra][cobra] to construct command-line tools.

[stdlib-flag]: https://golang.org/pkg/log
[cobra]: https://github.com/spf13/cobra

## Development Tools

- Use `gvm` to manage multiple versions of golang and multiple GOPATHs
