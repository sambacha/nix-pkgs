let
  # copies the the given `srcPath` to the nix store,
  # but only the files and directories explicitely
  # listed in `includePaths`.
  #
  # Example:
  #   filterExact ./. [
  #     "foo.txt"
  #     "src"
  #     "tests/test_"
  #   ]
  #
  # will copy the directory of this nix file to the store,
  # but only `foo.txt`, and the `src` directory, with all its
  # children (note: no trailing `/`!), and any file in
  # `tests/` starting with `test_`.
  filterExact = srcPath: includePaths:
    let
      # the `builtins.filterSource` function will always give absolute paths,
      # so we first have to make our includePaths absolute, relative to the srcPath.
      absoluteIncludePaths =
        map
          (p: toString srcPath + "/" + p)
          includePaths;
    in
      builtins.filterSource
        (path: type:
          # The builtins.filterSource is only recursing into directories if they have been selected.
          # We recurse into a directory, if it’s a prefix of any of our source selectors.
          # We can’t just recure into every directory, because it will blow up the function quadratically,
          # and `node_modules` is a thing …
          # (we should use a better source matching library at one point,
          # Robert Hensing has a proposed API in https://github.com/NixOS/nixpkgs/pull/112083 )
          if type == "directory" then
            builtins.any
              (includePath: hasPrefix path includePath)
              absoluteIncludePaths
          else
          # If it’s not a directory, we check if any of our sources selectors is a prefix of the path
          builtins.any
            (includePath: hasPrefix includePath path)
            absoluteIncludePaths)
        srcPath;

in {
  inherit filterExact;
}
