#!/usr/bin/env bash
# install.sh — Crée les liens symboliques pour bin/ et dotfiles/

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${REPO_DIR}/bin"
DOTFILES_DIR="${REPO_DIR}/dotfiles"
LOCAL_BIN="${HOME}/.local/bin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[~]${NC} $*"; }
error() { echo -e "${RED}[!]${NC} $*"; }

backup() {
    local target="$1" sudo_cmd="${2:-}"
    if [[ -e "${target}" && ! -L "${target}" ]]; then
        local bak="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        ${sudo_cmd} mv "${target}" "${bak}"
        warn "sauvegarde : ${target} → ${bak}"
    fi
}

# Lit la valeur d'un champ d'en-tête (« # KEY : valeur » ou « // KEY : valeur »)
header() {
    grep -E "^\s*(#|//)\s*$2\s*:" "$1" | head -1 | sed -E "s/^\s*(#|\/\/)\s*$2\s*:\s*//" || true
}

# OS courant : « wsl », sinon l'ID de /etc/os-release (fedora, ubuntu, arch...)
detect_os() {
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ -r /etc/os-release ]]; then
        (. /etc/os-release && echo "${ID:-unknown}")
    else
        echo "unknown"
    fi
}

CURRENT_OS="$(detect_os)"
info "OS détecté : ${CURRENT_OS}"

# ── bin/ → ~/.local/bin ──────────────────────────────────────────────────────

echo ""
echo "==> bin/"
mkdir -p "${LOCAL_BIN}"

for file in "${BIN_DIR}"/*; do
    [[ -f "${file}" ]] || continue
    name="$(basename "${file}")"
    target="${LOCAL_BIN}/${name}"
    backup "${target}"
    ln -sf "${file}" "${target}"
    info "bin: ${name} → ${target}"
done

# ── dotfiles/ → TARGET lu depuis l'en-tête ───────────────────────────────────

echo ""
echo "==> dotfiles/"

for file in "${DOTFILES_DIR}"/*; do
    [[ -f "${file}" ]] || continue
    name="$(basename "${file}")"

    # Ignorer si WARN présent
    if [[ -n "$(header "${file}" WARN)" ]]; then
        warn "dotfiles: ${name} ignoré (WARN)"
        continue
    fi

    # Ignorer si OS listé et ne correspondant pas (champ absent = tous les OS)
    os_list="$(header "${file}" OS)"
    if [[ -n "${os_list}" && " ${os_list} " != *" ${CURRENT_OS} "* ]]; then
        warn "dotfiles: ${name} ignoré (OS : ${os_list})"
        continue
    fi

    target_raw="$(header "${file}" TARGET)"
    if [[ -z "${target_raw}" ]]; then
        error "dotfiles: ${name} — aucune ligne TARGET trouvée, ignoré"
        continue
    fi

    # Remplacer le ~ initial par $HOME
    target="${target_raw/#\~/${HOME}}"

    # Créer le répertoire parent si nécessaire
    parent="$(dirname "${target}")"
    if [[ ! -d "${parent}" ]]; then
        if [[ "${target}" != "${HOME}"* ]]; then
            sudo mkdir -p "${parent}"
        else
            mkdir -p "${parent}"
        fi
    fi

    # Chemins système : utiliser sudo
    if [[ "${target}" != "${HOME}"* ]]; then
        backup "${target}" sudo
        sudo ln -sf "${file}" "${target}"
    else
        backup "${target}"
        ln -sf "${file}" "${target}"
    fi
    info "dotfiles: ${name} → ${target}"
done

# ── extension/custom-icons → ~/.vscode/extensions/custom-icons ──────────────
# Chemin attendu par les associations « ../../custom-icons/... » de material-icon-theme.
# Sous WSL, les extensions UI vivent côté Windows : non géré ici.

echo ""
echo "==> extension/"
VSCODE_EXT_DIR="${HOME}/.vscode/extensions"
if [[ "${CURRENT_OS}" == "wsl" ]]; then
    warn "extension: ignoré sous WSL (copier extension/custom-icons dans %USERPROFILE%/.vscode/extensions/)"
elif [[ -d "${VSCODE_EXT_DIR}" ]]; then
    backup "${VSCODE_EXT_DIR}/custom-icons"
    ln -sfn "${REPO_DIR}/extension/custom-icons" "${VSCODE_EXT_DIR}/custom-icons"
    info "extension: custom-icons → ${VSCODE_EXT_DIR}/custom-icons"
else
    warn "extension: ${VSCODE_EXT_DIR} absent, VS Code non installé ?"
fi

# ── Dépendances ──────────────────────────────────────────────────────────────

echo ""
echo "==> dépendances"
missing=0
for cmd in zsh git tmux eza bat starship zoxide direnv delta; do
    if ! command -v "${cmd}" &>/dev/null; then
        error "manquant : ${cmd}"
        missing=$((missing + 1))
    fi
done
if [[ ! -f "${HOME}/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
    error "manquant : zinit (git clone https://github.com/zdharma-continuum/zinit ~/.local/share/zinit/zinit.git)"
    missing=$((missing + 1))
fi
[[ ${missing} -eq 0 ]] && info "toutes les dépendances sont présentes"

echo ""
info "Terminé."
