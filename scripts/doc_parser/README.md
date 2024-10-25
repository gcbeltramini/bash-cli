# Documentation parsing

This folder contains the required code to parse the documentation in the `commands` folder. We use
the `docopt` syntax, explained at <http://docopt.org/>.

There are [implementations in many languages](https://github.com/orgs/docopt/repositories?q=docopt),
and we chose the Python library <https://github.com/jazzband/docopt-ng/>, because the command
`python` is available in all Mac computers and the repo is being actively maintained.

To avoid installing external packages and to enable customizations, the code was copied to folder
[docopt_ng](docopt_ng). How it works:

1. The CLI parses the text that starts with `##?` in the commands.
2. The parsed Python `dict` is converted into a string compatible with `bash`, so that the variables
   can be exported.
3. The modifications in the original code are identified by `# cli customization`.
