#!/usr/bin/env bash

# ----------------------------------------------------------
# Script d'installation Zsh + Oh My Zsh + Powerlevel10k + plugins
# ----------------------------------------------------------

set -e

# ----------------------------
# 1. Mettre à jour Ubuntu
# ----------------------------
echo "🛠 Mise à jour des paquets..."
sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt clean

# ----------------------------
# 2. Installer Zsh
# ----------------------------
echo "💻 Installation de Zsh..."
sudo apt install zsh git curl -y

# ----------------------------
# 3. Prompt utilisateur
# ----------------------------
read -rp "Entrez votre nom complet (FULLNAME) : " FULLNAME
read -rp "Entrez votre nom d'utilisateur (USER) : " USER
read -rp "Entrez votre email (EMAIL) : " EMAIL

# ----------------------------
# 4. Installer Oh My Zsh
# ----------------------------
echo "✨ Installation d'Oh My Zsh..."
export RUNZSH=no  # pour éviter le lancement automatique du script
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# ----------------------------
# 5. Installer thème et plugins OMZ
# ----------------------------
echo "🔌 Installation du thème Powerlevel10k et des plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# Thème
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# Plugins
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
git clone https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ----------------------------
# 6. Copier fichiers de configuration
# ----------------------------
echo "📂 Configuration de Zsh et Git..."

CONFIG_FILES=(".zshrc" ".p10k.zsh" ".gitconfig")

for file in "${CONFIG_FILES[@]}"; do
    if [[ ! -f "./$file" ]]; then
        echo "⚠️  Fichier $file introuvable dans le dossier courant. Assurez-vous qu'il existe."
        continue
    fi

    # Remplacement des variables
    sed -e "s/{{FULLNAME}}/$FULLNAME/g" \
        -e "s/{{USER}}/$USER/g" \
        -e "s/{{EMAIL}}/$EMAIL/g" "./$file" > "$HOME/$file"

done

# ----------------------------
# 7. Définir Zsh par défaut
# ----------------------------
echo "🔧 Définition de Zsh comme shell par défaut..."
chsh -s "$(which zsh)"

echo "✅ Installation terminée ! Fermez et rouvrez le terminal pour appliquer Zsh."
