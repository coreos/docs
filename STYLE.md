# Documentation style and formatting

## English style

Write short sentences. Organize concepts in paragraphs. Prefer lists to tables and paragraphs to lists. Write in the active voice. Avoid jargon beyond the requirements of subject and audience.

### Eschew you

You write unambiguous documentation, so you avoid the second person. Avoiding personal pronouns in general helps produce the imperative impersonal tone desired for documentation. Don't reboot your system or have the user reboot their system. Reboot the system.

### Generalities

There are a few other common ways to write or not write things:

* Expand acronyms on their introduction in a document, with the short form following in parentheses: Trusted Platform Module (TPM).
* Terms of art that are not commands or other literal text should often be italicized on their first appearance in a document: *Kubernetes* is a good example.
* The hyphen is overused and most English compounds do not require it.
* There is one space (` `) after a period (aka *full stop*, `.`), comma (`,`), semicolon (`;`) and other marks of punctuation.

## Source formatting

CoreOS documentation is written in [Markdown][mdhome], a simple way to annotate text to indicate presentation typesetting. Markdown source is intended to be a plain text human-readable version of the document, even before conversion to HTML for the browser or other display.

### Source file naming and encoding

Write Markdown source in UTF-encoded plain text files, named with a reasonable, lower case short form of the document's title, and suffixed with `.md`. Prefer hyphens to underscores in file names with two or more words. For example, instructions for DNS configuration are written to a file named [`configuring-dns.md`][configuring-dns].

### Line wrapping considered harmful

Don't wrap long lines of text with manual newlines. Line wrapping churns prose documents, because lines not actually edited will nevertheless change when a paragraph is edited and rewrapped.

### One sentence per line deprecated

Writing Markdown source with a newline between every sentence is acceptable to most compilers and can ease change review. However, this format makes the document less readable in source form. Do not add a line break between sentences. Write natural English paragraphs, separated by a single blank line.

### Preferred markdown symbols

Markdown defines two or more ways to declare some document structures. This documentation prefers these Markdown symbols among their alternatives:

* Headings are denoted in Markdown's ATX style, with hash character(s): `#`. See [*Headings*][headings], below.
* Bulleted lists, like this one, are denoted with the asterisk (`*`), rather than the hyphen.
* Hyperlink URLs are given in the reference style (`[hyperlinked text][label]`), rather than inline. Hyperlink labels are defined in one list at the end of the document. Relative links are preferred to absolute links. See [*Hyperlink Considerations*][hyperlink-considerations], below.
* *Italic text* is wrapped with a pair of single asterisks: `*Italics*`; **Bold** with a double pair: `**Bold**`.
* `Monospace` is indicated between a pair of backticks. This distinguishes literal strings like command names, file paths, or values, e.g., `/bin/markdown`. See [*Command Line Grammar*][command-line-grammar], below.
* Longer code blocks or file contents are *fenced*: Set off on new lines between pairs of three backticks, rather than indented. A presentation hint specifying the block's language can be given immediately after the opening three backticks, e.g., ````yaml`.

## Headings

By convention, the level one heading, denoted in Markdown by a single hash character (`#`), is the document's title. This document's title is *Documentation style and formatting*.

### Heading style

Each heading is both preceded and followed by a newline. A space separates the Markdown symbols from the heading text. Headings are typed in *Sentence case*, capitalizing the first letter of the first word, but other words only as they would be capitalized if appearing in the middle of a sentence.

### Heading semantics and the sidebar outline

Section headings expose the document's logical structure with a notation of incrementing hash marks (`#[#][...]`) for increasingly nested levels of a hierarchy. With the level one heading devoted to the document title, the second-level headings represent the document's primary concepts.

The site deployment process inspects a document's headings to derive the thumb index outlines seen in the right sidebar of [documentation viewed at CoreOS.com][coreos-docs].

#### Example: This document's source

The abridged skeletal markdown source for this document's headings:

```
# Documentation style and formatting

## English style

### Eschew you

[...]

## Headings

### Heading style

[...]

## Hyperlink considerations

### Naming

### Marking down the link

#### Example: Reference-style hyperlinking

[...]

## Command line grammar

### Example: Documenting `echo(1)`

[...]

## File name extension conventions
```

### Example: The "average" document

Most documents have a single `h1` (`#`) heading matching the title, two to five `h2` (`##`) headings representing the topic's primary concepts, and one or two `h3` (`###`) and `h4` (`####`) headings organizing details beneath each `h2`.

If a document proves a great deal longer or more structurally complex than those simplistic rules of thumb, there should be a good reason.

## Hyperlink considerations

### Naming

Name hyperlinks carefully to give them maximum context. For example, note that certain information is in the [style guide][style], rather than just pointing lazily to the style guide [here][style]. The link text "here" gives almost no information about its target. It is helpful to [write a clear sentence][eos] first, then bracket the choice words within to declare them a hyperlink.

### Marking down the link

As mentioned above, the reference style of Markdown hyperlinking is preferred to the inline. Hyperlinks are marked with two pairs of square brackets, the first enclosing the hyperlinked text, the second enclosing a label for the link. Labels are in turn associated with a target URL in a list of declarations at the end of the document. Each label declaration consists of a line beginning with the bracket-enclosed label, a colon, and the target URL (the `href` in HTML). The target URL may optionally be followed by a link title in double quotes. The list of link label declarations should be sorted alphabetically.

#### Example: Reference-style hyperlinking

```markdown
The reference style of [Markdown hyperlinks][mdlinks] allows for easier
reading of source and formalizes the declaration of links.

Another paragraph may reference the [project introduction][readme],
which link will likewise have its label defined at the document's foot.

[mdlinks]: http://daringfireball.net/projects/markdown/syntax#link "Markdown link syntax"
[readme]: README.md
```
#### Relative URLs preferred

Using relative URLs where possible helps portability among multiple presentation targets, as they remain valid even as the site root moves. Absolute linking is obviously necessary for resources external to the document's repository and/or the coreos.com domain.

For example, there are two ways to refer to the [CoreOS quick start guide][quickstart]'s location. The preferred way is a relative link from the current file's path to the target, which from this document is `os/quickstart.md`. An absolute link to the complete URL is less flexible, and more verbose: `https://github.com/coreos/docs/blob/master/os/quickstart.md`.

#### Hyperlink deployment automation

CoreOS documents have two major publication targets: the [coreos.com documentation library][coreos-docs], and [GitHub's Markdown presentation][githubmd]. The deployment scripts used to build the CoreOS site handle some of the wrinkles arising between the two targets. These scripts expect links to other CoreOS project documentation to refer to the Markdown source; that is, to end with the `.md` file extension. The deployment scripts rewrite hyperlinks to replace that extension with `.html` for presentation. This allows the links to be valid in either context. External links are not rewritten.

## Command line grammar

*Commands* *invoke* or *execute* programs. Commands *take* *arguments* and *accept* *options*, which themselves may be *set* to *values*.

### Example: Documenting `echo(1)`

In this simple command line:

```sh
$ echo -n Example
Example
```

`echo` is the command, and `Example` is the argument. The option `-n` suppresses the terminating newline usually emitted by `echo`. A binary option represented by a single letter, like `-n`, is sometimes called a *flag*. The `echo(1)` command prints its argument on the standard output, and a good shell excerpt often includes the expected output of commands, as shown here. The shell prompt character `$` distinguishes input from output.

### Example: Documenting subcommands

Some command lines are more complex. Many commands operate through a set of *subcommands*. `rkt` and several other relevant programs follow this pattern.

```sh
$ rkt run --debug example.aci
[...]
```

In this case the argument to `rkt`, `run`, is a subcommand. `run` in turn accepts the `--debug` option to modify how it executes the ACI image specified by its own argument, `example.aci`

### Example: Long command lines

Some commands pack many subcommands, arguments, and options on a single line. It is good practice to break such long command lines with newlines, escaped with backslash (`\`), because lines inside code blocks are not soft-wrapped in most presentations. For very long command lines, choose points that break the parameters into logical groups. Lines so wrapped are not indented for vertical alignment.

```sh
$ docker run --name docsbuilder \
-i -t \
-p 80:9001 -p 443:9443 \
-v /home/core/site:/app:rw \
-v /etc/ssl/certs:/etc/ssl/certs:ro \
quay.io/coreosinc/coreos-pages-builder scripts/deploy stage
```

## File name extension conventions

Some file types are commonly identified with more than one file name extension. For example, YAML is usually stored in files whose names end in either `.yml`, or `.yaml`. For the sake of consistency, use the file name extension designated in the following list when referring to or creating files of any of the listed types in CoreOS projects and their documentation.

* YAML: `file.yaml` is preferred to `file.yml`
* HTML: `file.html`, not `file.htm`


[command-line-grammar]: #command-line-grammar
[configuring-dns]: os/configuring-dns.md
[coreos-docs]: https://coreos.com/docs/
[eos]: https://faculty.washington.edu/heagerty/Courses/b572/public/StrunkWhite.pdf "The Elements of Style"
[githubmd]: https://help.github.com/articles/github-flavored-markdown/
[headings]: #headings
[hyperlink-considerations]: #hyperlink-considerations
[mdhome]: https://daringfireball.net/projects/markdown/syntax
[quickstart]: os/quickstart.md "Relative link from here to CoreOS Quick Start"
[style]: STYLE.md "CoreOS Documentation Style"
