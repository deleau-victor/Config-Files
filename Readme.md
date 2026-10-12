# Fichiers de configurations

Config partagée entre mes machines (Fedora native, Fedora sous WSL) et templates de projets.

```bash
./install.sh
```

Le script est idempotent : il peut être relancé à chaque mise à jour du repo.

## Structure

| Dossier      | Rôle                                                                         |
| ------------ | ---------------------------------------------------------------------------- |
| `bin/`       | Scripts liés dans `~/.local/bin`                                             |
| `dotfiles/`  | Fichiers de config liés vers la cible indiquée dans leur en-tête             |
| `extension/` | Icônes custom de material-icon-theme (→ `~/.vscode/extensions/custom-icons`) |
| `templates/` | Fichiers de démarrage de projets, copiés par `init-project`                  |

## En-têtes des dotfiles

Chaque fichier de `dotfiles/` commence par un en-tête (`#` ou `//`) lu par `install.sh` :

```
# SOURCE   : ~/Sources/System/Config/dotfiles/zsh.conf   (informatif)
# TARGET   : ~/.zshrc                                     (obligatoire : destination du symlink)
# DESC     : Configuration ZSH                            (informatif)
# OS       : fedora                                       (optionnel : liste d'OS séparés par des espaces)
# WARN     : Ne pas monter ce fichier en symlink          (optionnel : fichier ignoré par install.sh)
```

- **OS** : `wsl` sous WSL, sinon l'`ID` de `/etc/os-release` (`fedora`, `ubuntu`...). Sans ce champ, le fichier est installé partout.
- **WARN** : pour les fichiers système qui doivent être copiés à la main (GRUB, rEFInd).
- Une cible hors de `$HOME` est liée avec `sudo`.
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

`install.sh` signale celles qui manquent : `zsh`, `git`, `tmux`, `eza`, `bat`, `starship`, `zoxide`, `direnv`, `delta`, et [zinit](https://github.com/zdharma-continuum/zinit).

Polices : JetBrainsMono Nerd Font.

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
