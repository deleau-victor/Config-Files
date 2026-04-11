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

# ── bin/ → ~/.local/bin ──────────────────────────────────────────────────────

echo ""
echo "==> bin/"
mkdir -p "${LOCAL_BIN}"

for file in "${BIN_DIR}"/*; do
    [[ -f "${file}" ]] || continue
    name="$(basename "${file}")"
    target="${LOCAL_BIN}/${name}"
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
    if grep -qE '^\s*(#|//)\s*WARN\s*:' "${file}"; then
        warn "dotfiles: ${name} ignoré (WARN)"
        continue
    fi

    # Lire la ligne TARGET (supporte # et //)
    target_raw="$(grep -E '^\s*(#|//)\s*TARGET\s*:' "${file}" | head -1 | sed -E 's/^\s*(#|\/\/)\s*TARGET\s*:\s*//')"

    if [[ -z "${target_raw}" ]]; then
        error "dotfiles: ${name} — aucune ligne TARGET trouvée, ignoré"
        continue
    fi

    # Remplacer ~ par $HOME
    target="${target_raw/\~/${HOME}}"

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
        sudo ln -sf "${file}" "${target}"
    else
        ln -sf "${file}" "${target}"
    fi
    info "dotfiles: ${name} → ${target}"
done

echo ""
info "Terminé."
