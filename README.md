<picture height="60">
    <source media="(prefers-color-scheme: dark)" srcset="https://cdn.bittivirta.fi/graphics/logo/2023/bittivirta/svg/logo-alt.svg">
    <img alt="Bittivirta Logo" src="https://cdn.bittivirta.fi/graphics/logo/2023/bittivirta/svg/logo.svg" height="60">
</picture>
<br/>
<br/>

# Bittivirta Staff SSH Keys

This repository contains the public SSH keys of Bittivirta staff members. The keys are used to grant access to servers.

## Running the script

To run the script, simply run the following command:

```bash
bash <(curl -s 'https://raw.githubusercontent.com/bittivirta/ssh-keys/main/importer.sh')
```

**Note:** Run the script as user, you want to import the keys to. This is usually the `root` user or user with `sudo` privileges. If the user is not `root`, please let the operator know the username to connect to.

### Script dependencies

- `curl`
- `jq` (gjq on macOS)
