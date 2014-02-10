posh
====

my posh utilities and helper snippets

### Count uniq items in sets of things that match a pattern
* pattern is a regex, select-string returns a "match" object
* indexing -1 on split gets the /last/ item in the split

`cat -path <file,file,...> | select-string -pattern "pattern" | %{ $_.ToString().Split(' ')[-1]; } | group`
