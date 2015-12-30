# How to Contribute

CoreOS documentation is released under the [Apache 2.0 License][asl], and we welcome contributions. Check out the [help-wanted tag][help-wanted] in this project's Issues list for good places to start participating.

Submit fixes and additions in the form of [GitHub *Pull Requests* (PRs)][pull-requests]. The general process is the typical git fork-branch-PR-review-merge cycle:

1. Fork this repository into your GitHub account
2. Make changes in a topic branch or your fork's `master`
3. Send a Pull Request from that topic branch to coreos/docs
4. Maintainers will review the PR and either merge it or make comments

Cognizance of the tribal customs described and linked to below will help get your contributions incorporated with the greatest of ease.

## Clear commit messages

Commit messages follow a format that makes clear **what** changed and **why** it changed. The first line of each commit message should clearly state what module or file changed, summarize the change very briefly, and should end, without a period, somewhere short of 70 characters. After a blank line, the body of the commit message should then explain why the change was needed, with lines wrapped at 72 characters wide and sentences normally punctuated. Cite related issues or previous revisions as appropriate. For example:

```
ignition: Update etcd example to use %m

Make the etcd configuration example use ignition's %m instead of the
ETCD_NAME environment variable. Fixes #123.
```

This format can be described somewhat more formally as:

```
<module or file name>: <what changed>
<BLANK LINE>
<why this change was made>
<BLANK LINE>
[<footer>]
```

Where the optional `[<footer>]` might include `signed-off-by` lines and other metadata.

## Style guide

The [style guide][style] prescribes the conventions of formatting and English style preferred in CoreOS project documentation.

## Translations

We happily accept accurate translations. Please send the documents as a pull request and follow two guidelines:

1. Name the files identically to the originals, but put them beneath a directory named for the translation's `gettext` locale. For example: `JA_JP/doc.md`, `ZH_CN/doc.md,` or `KO_KN/doc.md`.

2. Add an explanation about the translated document to the top of the file: "These documents were translated into Esperanto by Community Member <person@example.com> and last updated on 2015-12-01. If you find inaccuracies or problems please file an issue on GitHub."


[asl]: LICENSE
[coreos-docs]: https://coreos.com/docs/
[help-wanted]: https://github.com/coreos/docs/issues?q=is%3Aopen+label%3Ahelp-wanted
[pull-requests]: https://help.github.com/articles/using-pull-requests/
[style]: STYLE.md "CoreOS Documentation Style and Formatting"
