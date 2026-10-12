#!/usr/bin/env bash
# install-deps.sh — Installe les dépendances de la config (Fedora / dnf)
# Usage : ./install-deps.sh [--check]
#   --check : liste seulement ce qui manque (code de sortie 1 si incomplet)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[~]${NC} $*"; }
error() { echo -e "${RED}[!]${NC} $*"; }

ZINIT_DIR="${HOME}/.local/share/zinit/zinit.git"
FONTS_DIR="${HOME}/.local/share/fonts/JetBrainsMonoNerd"
LOCAL_BIN="${HOME}/.local/bin"

# Dépendances : « nom:méthode:paquet »
#   dnf    → sudo dnf install <paquet>
#   script → installeur dédié (fonction install_<nom>)
DEPS=(
    "zsh:dnf:zsh"
    "git:dnf:git"
    "tmux:dnf:tmux"
    "eza:dnf:eza"
    "bat:dnf:bat"
    "zoxide:dnf:zoxide"
    "direnv:dnf:direnv"
    "delta:dnf:git-delta"
    "starship:script:"
    "zinit:script:"
)

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null
}

# Police uniquement sur Linux natif : sous WSL, c'est le terminal Windows qui affiche
is_wsl || DEPS+=("unzip:dnf:unzip" "fc-cache:dnf:fontconfig" "nerd-font:script:")

is_installed() {
    case "$1" in
        zinit)     [[ -f "${ZINIT_DIR}/zinit.zsh" ]] ;;
        nerd-font) fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd" ;;
        *)         command -v "$1" &>/dev/null ;;
    esac
}

install_starship() {
    mkdir -p "${LOCAL_BIN}"
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "${LOCAL_BIN}"
}

install_zinit() {
    git clone --depth 1 https://github.com/zdharma-continuum/zinit "${ZINIT_DIR}"
}

install_nerd-font() {
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "${tmp}/font.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    mkdir -p "${FONTS_DIR}"
    unzip -oq "${tmp}/font.zip" '*.ttf' -d "${FONTS_DIR}"
    rm -rf "${tmp}"
    fc-cache -f "${FONTS_DIR}"
}

# ── Inventaire ───────────────────────────────────────────────────────────────

missing_dnf=()
missing_script=()
for dep in "${DEPS[@]}"; do
    IFS=: read -r name method package <<< "${dep}"
    is_installed "${name}" && continue
    case "${method}" in
        dnf)    missing_dnf+=("${package}") ;;
        script) missing_script+=("${name}") ;;
    esac
done

if [[ ${#missing_dnf[@]} -eq 0 && ${#missing_script[@]} -eq 0 ]]; then
    info "toutes les dépendances sont présentes"
    exit 0
fi

for item in "${missing_dnf[@]}" "${missing_script[@]}"; do
    error "manquant : ${item}"
done

if [[ "${1:-}" == "--check" ]]; then
    exit 1
fi

# ── Installation ─────────────────────────────────────────────────────────────

if ! command -v dnf &>/dev/null; then
    error "dnf introuvable : ce script ne gère que Fedora, installer les paquets ci-dessus à la main"
    exit 1
fi

if [[ ${#missing_dnf[@]} -gt 0 ]]; then
    echo ""
    info "dnf : ${missing_dnf[*]}"
    sudo dnf install -y "${missing_dnf[@]}"
fi

# Après dnf : zinit a besoin de git, la police de fc-cache/unzip
for name in "${missing_script[@]}"; do
    echo ""
    info "installation : ${name}"
    "install_${name}"
done

echo ""
info "Terminé."
[[ "${SHELL}" == */zsh ]] || warn "shell par défaut : ${SHELL} (passer à zsh : chsh -s \"\$(command -v zsh)\")"
