  * TODO: Take the whole `bin/` mess apart and build all the date arithmetic 
  in a ruby cli based on `dry-cli` or `thor` or something.
  * TODO: Add in non-hardcoded mechanisms for dictating where the marc/delete
files will be, where the redirect file will be, etc. 
  * TODO: Get the rights info from `rights_current` so it's up-to-date. It
would be nice if `rights_current` had an index on the whole HTID instead
of us having to split out the namespace...
  * TODO: Put connection/ authentication info in ENV (and/or eventually k8s
    secrets)
  * TODO: Add an env variable to skip using the redirect file as well.
  * TODO: Change to use `dotenv`?
  * TODO: Add environment variables for file locations
  * TODO: Move `require/extend` code out of `common.rb` and into a file that
can be used without loading everything else in that file, making it easier
to run subsets of rules.
  * TODO: Decide if there's anything useful in the unused files in the
`indexers/` directory and ditch whatever we don't want.
  * TODO: Figure out if we can ditch `lib/umich_traject`
  * TODO: normalize/refactor all the macros
  * TODO: Document/refactor ht_item.rb