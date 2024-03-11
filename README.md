# go-mod-bump

Script to elegantly update direct Go modules in separate commits.

Automatically updates dependencies similar to `go get -u`, but commits the update to each direct
module in a separate commit.

## How to install

```shell
mkdir -p ~/bin
curl https://raw.githubusercontent.com/xorcare/go-mod-bump/main/go-mod-bump.sh > ~/bin/go-mod-bump
chmod +x ~/bin/go-mod-bump
```

After that don't forget to add the `~/bin` directory to the `$PATH` variable.
Use one of the following commands to do this:

```shell
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bashrc
# Or
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.zshrc
```

If you know a better way use it or let me know I will update the documentation.

## How to use

For update all direct models, use:

```shell
go-mod-bump all
```

For update one specific direct module, specify its name. For example:

```shell
go-mod-bump github.com/xorcare/pointer
```

For update multiple direct modules, specify their names. For example:

```shell
go-mod-bump github.com/xorcare/pointer github.com/xorcare/tornado
```

Also, you can add custom prefix for git message. For example:

```shell
go-mod-bump -p 'build(deps): ' all
```

<details>
    <summary>Git log with message prefix example</summary>

    build(deps): Bump github.com/xorcare/pointer from v1.0.0 to v1.1.1
    build(deps): Bump github.com/xorcare/tornado from v0.1.0 to v0.1.1
    build(deps): Bump github.com/xorcare/golden from v0.6.0 to v0.8.2

</details>

## Know issues and limitations

- The script does not know how to work with `replace` directive, if it is used in your project be
  careful and do not forget to update dependencies manually.
- Pipelines are not supported, you cannot use go-mod-bump in combination with `|`.
- The script runs very slowly on projects with a lot of dependencies.
- The script does not abort execution if a module fails to update. It will try to update other
  modules if possible.

## Disclaimer

When using this script, you should be aware that it propagates changes to the Git history. In some
cases, you may lose all your uncommitted changes forever.

## Examples of output

<details>
    <summary>Log with all modules updated successfully</summary>

    go-mod-bump: upgraded github.com/xorcare/pointer v1.0.0 => [v1.1.1]
    go-mod-bump: upgraded github.com/xorcare/tornado v0.1.0 => [v0.1.1]
    go-mod-bump: upgraded github.com/xorcare/golden v0.6.0 => [v0.8.2]
    go-mod-bump: upgraded golang.org/x/crypto v0.0.0-20191011191535-87dc89f01550 => [v0.18.0]
    go-mod-bump: upgraded golang.org/x/lint v0.0.0-20200302205851-738671d3881b =>
    [v0.0.0-20210508222113-6edffad5e616]

</details>

<details>
    <summary>Log with on module update failed</summary>

    go-mod-bump: failed to update module github.com/xorcare/golden
    v0.0.0-20180918085934-3c96afc26e10 to v0.0.0-20200320164324-52e96869b7ff
    try to update module manually using commands:
    go get github.com/xorcare/golden@v0.0.0-20180918085934-3c96afc26e10
    go mod tidy
    go build ./...
    go-mod-bump: upgraded github.com/xorcare/tornado v0.1.0 => [v0.1.1]
    go-mod-bump: upgraded github.com/xorcare/pointer v1.0.0 => [v1.1.1]

</details>

<details>
    <summary>Git log example</summary>

    Bump github.com/xorcare/pointer from v1.0.0 to v1.1.1
    Bump github.com/xorcare/tornado from v0.1.0 to v0.1.1
    Bump github.com/xorcare/golden from v0.6.0 to v0.8.2
    Bump golang.org/x/crypto from v0.0.0-20191011191535-87dc89f01550 to v0.18.0
    Bump golang.org/x/lint from v0.0.0-20200302205851-738671d3881b to
    v0.0.0-20210508222113-6edffad5e616

</details>
