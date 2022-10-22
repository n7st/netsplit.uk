# netsplit.uk

Static site built with Hugo.

## Prerequisites

* [Hugo](https://gohugo.io/getting-started/installing/#fetch-from-github)

## Run the development webserver

With draft articles:

```
hugo serve -D
```

Without draft articles:

```
hugo serve
```

## Output to HTML

```bash
hugo -s .
```

## Clean up generated HTML

```bash
rm -r public
```

## License

MIT. See [`LICENSE`](https://git.netsplit.uk/mike/netsplit.uk/blob/master/LICENSE).
