# Contributing code to the opentitan repository

## Contributor License Agreement

Contributions to OpenTitan must be accompanied by sign-off text that indicates
acceptance of the Contributor License Agreement (see [CLA](CLA) for full
text), which is closely derived from the Apache Individual Contributor License
Agreement. The sign-off text must be included once per commit, in the commit
message. The sign-off can be automatically inserted using a command such as
`git commit -s`, which will generate the text in the form:
`Signed-off-by: Random J Developer <random@developer.example.org>`

By adding this sign-off, you are certifying:

_By signing-off on this submission, I agree to be bound by the terms of the
Contributor License Agreement located at the root of the project repository,
and I agree that this submission constitutes a "Contribution" under that
Agreement._

Please note that this project and any contributions to it are public and that
a record of all contributions (including any personal information submitted
with it, including a sign-off) is maintained indefinitely and may be
redistributed consistent with this project or the open source license(s)
involved.

## Quick guidelines

* Keep a clean commit history. This means no merge commits, and no long series
  of "fixup" patches (rebase or squash as appropriate). Structure work as a
  series of logically ordered, atomic patches. `git rebase -i` is your friend.
* Changes should be made via pull request, with review. A pull request will be
  committed by a "committer" (an account listed in `COMMITTERS`) once it has
  had an explicit positive review.
* When changes are restricted to a specific area, you are recommended to add a
  tag to the beginning of the first line of the commit message in square
  brackets. e.g. "[uart] Fix bug #157".
* Code review is not design review and doesn't remove the need for discussing
  implementation options. If you would like to make a large-scale change or
  discuss multiple implementation options, discuss on the mailing list.
* Create pull requests from a fork rather than making new branches in
  `github.com/lowrisc/opentitan`.
* Do not attempt to commit code with a non-Apache license without discussing
  first.
* If a relevant bug or tracking issue exists, reference it in the pull request
  and commits.
* Do not report security vulnerabilities through public GitHub issues or pull
  requests. For instructions on how to report vulnerabilities, please consult
  SECURITY.md.

Please see [Contributing to OpenTitan](https://opentitan.org/book/doc/contributing)
for more general guidance.
