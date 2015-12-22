# CoreOS Documentation

This repository contains the Markdown source of the [CoreOS documentation][coreos-docs].

## Contributing

The CoreOS documentation is released under the [Apache 2.0 License][asl], and we welcome contributions. Check out the [help-wanted tag][help-wanted] in this project's Issues list for good places to start participating.

Submit fixes and additions in the form of `git` *Pull Requests* (PRs). The general process is the typical git fork-branch-PR-review-merge cycle:

1. Fork this repository into your git workspace and/or GitHub account
2. Make changes in a topic branch or your fork's `master`
3. Send a Pull Request from the branch containing the changes
4. Maintainers will review the PR and either merge it or make comments

### Style guide

The [style guide][style] prescribes the conventions of formatting and English style preferred in CoreOS project documentation.

### Translations

We happily accept accurate translations. Please send the documents as a pull request and follow two guidelines:

1. Name the files identically to the originals, but put them beneath a directory named for the translation's `gettext` locale. For example: `JA_JP/doc.md`, `ZH_CN/doc.md,` or `KO_KN/doc.md`.

2. Add an explanation about the translated document to the top of the file: "These documents were translated into Esperanto by Community Member <person@example.com> and last updated on 2015-12-01. If you find inaccuracies or problems please file an issue on GitHub."


[asl]: LICENSE
[coreos-docs]: https://coreos.com/docs/
[help-wanted]: https://github.com/coreos/docs/issues?q=is%3Aopen+label%3Ahelp-wanted
[style]: STYLE.md "CoreOS Documentation Style and Formatting"
