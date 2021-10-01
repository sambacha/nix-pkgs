# `nix uPkgs`

- nix scripts and packages 

## Hydra

Lots of goodies like <githubstatus> pinging.
https://github.com/input-output-hk/iohk-ops/blob/bc8195de286d8b9b55b06f2046ab5412307a51b6/modules/hydra-master-common.nix

Declarative jobset bootstrapping:
https://github.com/shlevy/declarative-hydra-example

Declarative jobset with Git PR evals:
https://github.com/cleverca22/hydra-configs/tree/master/toxvpn

Other notes:
- Use git@github.com:owner/repo.git valued git inputs for private repos + see below
- Create a github deploy key for your repo, put it in /var/lib/hydra/.ssh
- Also create a /var/lib/hydra/.ssh/config file:

```
Host github.com
        StrictHostKeyChecking No
        UserKnownHostsFile /dev/null
        IdentityFile /var/lib/hydra/.ssh/id_rsa
```

- Alternatively set up the known hosts in advance with some ops script (can't find it now).

- `journalctl | grep -C1 hydra | tail` to see output.

- For githubpulls / githubstatus plugins, create a `<github_authorization>` section in the hydra config with a personal access token
  - repo scope for githubpulls, otherwise repo:status would be enough :/

Other resources:
- https://github.com/peti/hydra-tutorial

### Binary cache

- Can use `nix-serve` to expose a nix-store on HTTP.
  - It will on-the-fly compress stuff in the store into NAR files.
    - Example:
      - curl http://localhost:3000/gpl4id13hjbxm909srpxximik3b5lg3p.narinfo
      - curl http://localhost:3000/nar/gpl4id13hjbxm909srpxximik3b5lg3p.nar
        - The actual NAR url is found in the .narinfo (Hydra will pack into .nar.xz for example).

- Without extra config, Hydra also serves the binary cache from nix-store.
  - Drawback of serving the store is it might expose more than the build artifacts.
    - Source code etc.
    - Would need guessing the hash though (or sniping from a screenshot).
  - Other drawback is on-the-fly NAR creation might be costy (didn't measure).

- When Hydra is configured with `store_uri` (either local or remote like s3) ..
  - .. it writes the NAR files there directly.
    - This slows the build process upfront, but serving is faster.
      - Note: the first builds are especially slow, since it seems all deps from /nix/store are NAR-ified into the cache.
        - Hm, source derivations as well?
          - Yes. Ouch. Well.
    - Also takes space (if stored locally... well it takes space remotely as well ;).
  
  - The `binary_cache_secret_key_file` and `binary_cache_dir` options seem needed.
    - Logs warn they are not, but then NAR signing doesn't work otherwise.
      - See https://github.com/NixOS/hydra/issues/548
    
  - It seems Hydra won't serve the the binary cache it this mode
    - You can serve it yourself anyway.
    
- So its better to let Hydra write the cache, but actually serve it separately.
  - It is just a set of static files, so nginx can serve them statically.
    - Make sure to disable dir listing though.
  - Or upload to S3. See https://github.com/input-output-hk/iohk-ops/blob/master/modules/hydra-master-main.nix.

- Configure using the binary caches
  - https://unix.stackexchange.com/a/309963/20146
  
- How to serve a private binary cache?
  - Option: no auth, serve via private network (using nix-serve or direct file serving).
    - No auth..
  - Option: serve via ssh (https://nixos.org/nix/manual/#ssec-copy-closure)
    - Gives too much access to clients via ssh, but can work if needed fast.
      - Can be fixed, see link above.
    - Quickstart
      - nix-build --substituters ssh://root@116.203.94.206 --option require-sigs false pyurlex.nix
        - Don't know how to specify the signing key..
          - We don't have any NAR files in this pathway, so signing is likely not an option.
  - Option: upload to s3 bucket (or compatible).
    - Clients should have the right access keys in their env. Pretty flexible.
  
### What can trip up binary cache

- When local workdir doesn't match hydra one
  - Local hidden stuff (for `git status` at least):
    - Files ignored by .gitignore
      - use `git status --ignored`
    
    - Empty dirs (not put in git, so not present in the Hydra checkout)
      - `find . -type d -empty | grep -v \.git`
      
    - Dotfiles (often sneak under the radar).
      - Or dotdirs.
    
    - Using `filterSource ./.` or other stuff involving `./.`
      - Since the derivation of `./.` will leak the dir-name into the hash
        - Bad if this is the top-level dir, differing at various checkouts
          - https://github.com/NixOS/nix/issues/1305
            - TLDR use `builtins.path` until https://github.com/NixOS/nixpkgs/pull/56985 is done.

- Debugging the diff
  - Look into the `.drv` file, find the `src` input to the derivation.
    - It is the likely culprit. Compare the files with those present on Hydra.

## license 

GPL-2
