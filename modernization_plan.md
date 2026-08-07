## CI/CD modernization plan (by Barbie)

We need to update CI/CD workflows, such as `Tests.yml`, with three key modernizations.

### Adoption of `files_ignore_from_source_file`

In many workflows, there is a job that looks like this:

```yaml
    changes:
        runs-on: ubuntu-latest
        name: Assess changes
        steps:
            -   name: 💖 Checkout repository 💖
                uses: actions/checkout@v6

            -   name: 💖 Decide checks 💖
                uses: tj-actions/changed-files@v47
                id: changes
                with:
                    files_ignore: |
                        README.md
                        LICENSE
                        NOTICE
                        .mailmap
                        .gitignore
                        .github/FUNDING.yml
                        some_other_file.txt
                        another_ignored_file.txt
        outputs:
            code_changed: ${{ steps.changes.outputs.any_changed }}
```

We want to change it to adopt `files_ignore_from_source_file: .github/autosync/Skip.txt`:

```yaml
            -   name: 💖 Decide checks 💖
                uses: tj-actions/changed-files@v47
                id: changes
                with:
                    files_ignore_from_source_file: .github/autosync/Skip.txt
                    files_ignore: |
                        some_other_file.txt
                        another_ignored_file.txt
```

As you can see, paths that are present in the `Skip.txt` file are removed from `files_ignore`, if no paths remain, `files_ignore` should be removed entirely.

The `Skip.txt` file is supposed to be identical across all repos.


### Simplfying `if: ${{ ... }}` syntax

Double curly braces should be removed from the `if: ${{ needs.changes.outputs.code_changed == 'true' }}` conditionals wherever GitHub Actions supports the simplified syntax.

```yaml
    Linux:
        runs-on: ubuntu-24.04-arm
        name: Ubuntu 24.04
        needs: changes
        if: needs.changes.outputs.code_changed == 'true'
```

There might be other sites where double curly braces can be removed, if you encounter them, make a note of it and ask for approval before removing them.


### Updating invocations of `rarestype/swift-install-action`

In older repositories, the `rarestype/swift-install-action` step is spelled like this:

```yaml
            -   name: 💖 Install Swift 💖
                uses: rarestype/swift-install-action@v1
                with:
                    swift-prefix: "swift-6.3.3-release/ubuntu2404/swift-6.3.3-RELEASE"
                    swift-id: "swift-6.3.3-RELEASE-ubuntu24.04"
```

Stable Swift toolchain releases can be simplified to this:

```yaml
            -   name: 💖 Install Swift 💖
                uses: rarestype/swift-install-action@v1
                with:
                    swift-release: 6.3.3-RELEASE
```

which is the preferred modern syntax. All toolchains should already be aligned to `6.3.3-RELEASE`, if they are not, that is indicative of a larger error, and should be escalated to human review.