# Fichiers de configurations

## Script d'installation pour WSL

Le script d'installation pour WSL permet de configurer un environnement de développement sous Windows Subsystem for Linux (WSL) en automatisant l'installation et la configuration des outils et paramètres nécessaires.

Le prérequis pour exécuter ce script est d'avoir WSL installé et configuré sur votre machine Windows.

Pour cela :

1. Ouvrez PowerShell en tant qu'administrateur.

2. Vérifiez que WSL est installé en exécutant la commande suivante :

    ```powershell
    wsl -v
    ```

    Si WSL est installé, vous verrez la version de WSL affichée.
    Vérifiez également que vous utilisez WSL 2, qui est la version recommandée.
    Si vous voyez "WSL version 1", vous devrez mettre à niveau vers WSL 2 :

    ```powershell
    wsl --update
    wsl --set-default-version 2
    ```

    Si WSL n'est pas installé, vous pouvez l'installer en exécutant la commande suivante :

    ```powershell
    wsl --install
    ```

3. Redémarrez votre machine si nécessaire.

4. Installez une distribution Linux (par exemple, Ubuntu).
   Il est recommandé d'installer une distribution depuis les sources officielles des différentes distributions, par exemple pour ubuntu : [https://ubuntu.com/desktop/wsl](https://ubuntu.com/desktop/wsl)

    puis d'installer la distribution téléchargée via PowerShell en utilisant la commande suivante (en remplaçant le chemin par le chemin vers le fichier téléchargé) :

    ```powershell
    wsl --install --from-file <image>.wsl
    ```

5. Lancez la distribution Linux depuis le menu Démarrer et suivez les instructions pour configurer votre utilisateur.

Une fois WSL installé et configuré, vous pouvez exécuter le script d'installation pour configurer votre environnement de développement.
Pour exécuter le script d'installation, suivez ces étapes :

1. Ouvrez votre terminal WSL (par exemple, Ubuntu).

2. Naviguez jusqu'au répertoire où se trouve le script d'installation. Par exemple, si le script est dans le répertoire "Config-Files" de votre répertoire utilisateur Windows, vous pouvez y accéder via le chemin `/mnt/c/Chemin vers le répertoire Config-Files/wsl`.

3. Rendez le script exécutable en utilisant la commande suivante :

    ```bash
    sudo chmod +x install.sh
    ```

4. Exécutez le script avec la commande suivante :

    ```bash
    ./install.sh
    ```

## Configuration de l'éditeur Vs code

Pour accéder au fichier de paramètre de l'éditeur en json sur Visual studio code.

```
<!-- Windows -->
CTRL + SHIFT + P > Preferences : Open User Settings (JSON)

<!-- MacOS -->
CMD + SHIFT + P > Preferences : Open User Settings (JSON)
```

## Configuration des Snippets vs code

Pour accéder aux fichiers de snippets de l'éditeur sur Visual studio code.

```
<!-- Windows -->
CTRL + SHIFT + P > Snippets : Configure User Snippets > Target Language

<!-- MacOS -->
CMD + SHIFT + P > Snippets : Configure User Snippets > Target Language
```
