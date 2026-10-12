# Fichiers de configurations

Config partagée entre mes machines (Fedora native, Fedora sous WSL) et templates de projets.

```bash
./install.sh
```

Le script est idempotent : il peut être relancé à chaque mise à jour du repo.

## Structure

| Dossier      | Rôle                                                                                                                                   |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `bin/`       | Scripts liés dans `~/.local/bin`                                                                                                       |
| `dotfiles/`  | Fichiers de config liés vers la cible indiquée dans leur en-tête                                                                       |
| `extension/` | Icônes custom de material-icon-theme (→ `~/.vscode/extensions/custom-icons`, copiées dans `%USERPROFILE%\.vscode\extensions` sous WSL) |
| `templates/` | Fichiers de démarrage de projets, copiés par `init-project`                                                                            |

## En-têtes des dotfiles

Chaque fichier de `dotfiles/` commence par un en-tête (`#` ou `//`) lu par `install.sh` :

```
# SOURCE   : ~/Sources/System/Config/dotfiles/zsh.conf   (informatif)
# TARGET   : ~/.zshrc                                     (obligatoire : destination du symlink)
# DESC     : Configuration ZSH                            (informatif)
# OS       : fedora                                       (optionnel : liste d'OS séparés par des espaces)
# MODE     : copy                                         (optionnel : copie au lieu d'un symlink)
# WARN     : Ne pas monter ce fichier en symlink          (optionnel : fichier ignoré par install.sh)
```

- **TARGET** : `~` est remplacé par `$HOME` ; sous WSL, les variables Windows `%VAR%` (`%APPDATA%`, `%USERPROFILE%`...) sont résolues en chemin `/mnt/c/...`.
- **OS** : `wsl` sous WSL, sinon l'`ID` de `/etc/os-release` (`fedora`, `ubuntu`...). Sans ce champ, le fichier est installé partout.
- **WARN** : pour les fichiers système qui doivent être copiés à la main (GRUB, rEFInd).
- **MODE : copy** : pour les cibles lues par Windows (`/mnt/c/...`), qui ne sait pas suivre un symlink WSL. La copie n'est faite que si le contenu diffère ; une modification faite côté Windows est sauvegardée en `.bak` puis remplacée.
- `sudo` n'est utilisé que si le dossier cible n'est pas inscriptible (`/etc/...`).
- Un fichier existant (non symlink) est sauvegardé en `<cible>.bak.<date>` avant d'être remplacé.

## Surcharges par machine

Non versionnées, à créer à la main si besoin :

- `~/.gitconfig.local` : identité pro, `sshCommand`, `editor`...
  ```ini
  [user]
    email = prenom.nom@entreprise.com
  ```
  Ou par dossier, pour n'appliquer l'identité pro qu'aux repos pro :
  ```ini
  [includeIf "gitdir:~/Sources/Repos/Work/"]
    path = ~/.gitconfig.work
  ```

## Dépendances

```bash
./install-deps.sh           # installe ce qui manque (Fedora / dnf)
./install-deps.sh --check   # liste seulement (aussi appelé en fin d'install.sh)
```

| Dépendance                                                      | Installation                                                                                                  |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `zsh`, `git`, `tmux`, `eza`, `bat`, `zoxide`, `direnv`, `delta` | `dnf` (`delta` = paquet `git-delta`)                                                                          |
| `starship`                                                      | installeur officiel → `~/.local/bin` (absent des dépôts Fedora)                                               |
| [zinit](https://github.com/zdharma-continuum/zinit)             | `git clone` → `~/.local/share/zinit/zinit.git`                                                                |
| JetBrainsMono Nerd Font                                         | release GitHub → `~/.local/share/fonts` (Linux natif uniquement : sous WSL, installer la police côté Windows) |

## Templates de projets

```bash
cd mon-projet
init-project dotnet          # common + dotnet
init-project dotnet web      # plusieurs profils
init-project -f dotnet       # écrase les fichiers existants
```

| Profil   | Fichiers                                                                                                   |
| -------- | ---------------------------------------------------------------------------------------------------------- |
| `common` | `.editorconfig` (socle), `.gitattributes` — toujours copiés                                                |
| `dotnet` | `.editorconfig` (règles C#/analyseurs), `Directory.Build.props`, `Directory.Packages.props`, `global.json` |
| `web`    | `.editorconfig` (JS/TS/Vue/CSS/JSON), `.prettierrc`                                                        |

`.editorconfig` est un fichier **fusionné** : `init-project` concatène le fragment `common` puis ceux des profils demandés (un seul `root = true`, dans `common`). Les autres fichiers sont copiés tels quels.

Les projets .NET utilisent xunit v3 sur Microsoft.Testing.Platform : `dotnet test`, avec `--coverage` pour la couverture. Tout projet dont le nom finit par `Tests` est détecté comme projet de test.
