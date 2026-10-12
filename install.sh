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

# Variable d'environnement Windows (ex. APPDATA) convertie en chemin WSL (/mnt/c/...)
# Vide si indisponible (hors WSL ou variable inexistante)
win_var() {
    local value
    value="$(cd /mnt/c && cmd.exe /c "echo %$1%" 2>/dev/null | tr -d '\r')" || return 0
    if [[ -n "${value}" && "${value}" != "%$1%" ]]; then
        wslpath -u "${value}"
    fi
    return 0
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

    # Remplacer les variables Windows %VAR% (WSL uniquement)
    while [[ "${target}" =~ %([A-Za-z_][A-Za-z0-9_]*)% ]]; do
        var="${BASH_REMATCH[1]}"
        value="$(win_var "${var}")"
        if [[ -z "${value}" ]]; then
            error "dotfiles: ${name} — variable Windows %${var}% introuvable, ignoré"
            continue 2
        fi
        target="${target//%${var}%/${value}}"
    done

    # sudo seulement si le premier dossier existant de la cible n'est pas inscriptible
    parent="$(dirname "${target}")"
    existing="${parent}"
    while [[ ! -d "${existing}" ]]; do existing="$(dirname "${existing}")"; done
    sudo_cmd=""
    [[ -w "${existing}" ]] || sudo_cmd="sudo"

    [[ -d "${parent}" ]] || ${sudo_cmd} mkdir -p "${parent}"

    # MODE : copy → copie au lieu d'un symlink (ex. fichiers lus depuis Windows,
    # qui ne sait pas suivre un symlink WSL pointant vers le système de fichiers Linux)
    if [[ "$(header "${file}" MODE)" == "copy" ]]; then
        [[ -L "${target}" ]] && ${sudo_cmd} rm "${target}"
        if [[ -f "${target}" ]] && cmp -s "${file}" "${target}"; then
            info "dotfiles: ${name} → ${target} (copie déjà à jour)"
            continue
        fi
        backup "${target}" ${sudo_cmd}
        ${sudo_cmd} cp "${file}" "${target}"
        info "dotfiles: ${name} → ${target} (copie)"
        continue
    fi

    backup "${target}" ${sudo_cmd}
    ${sudo_cmd} ln -sf "${file}" "${target}"
    info "dotfiles: ${name} → ${target}"
done

# ── extension/custom-icons → <extensions VS Code>/custom-icons ───────────────
# Chemin attendu par les associations « ../../custom-icons/... » de material-icon-theme.
# Sous WSL, les extensions UI vivent côté Windows : copie (Windows ne suit pas
# les symlinks WSL), sinon symlink.

echo ""
echo "==> extension/"
ICONS_SRC="${REPO_DIR}/extension/custom-icons"
if [[ "${CURRENT_OS}" == "wsl" ]]; then
    win_profile="$(win_var USERPROFILE)"
    VSCODE_EXT_DIR="${win_profile:+${win_profile}/.vscode/extensions}"
else
    VSCODE_EXT_DIR="${HOME}/.vscode/extensions"
fi
ICONS_DST="${VSCODE_EXT_DIR}/custom-icons"

if [[ -z "${VSCODE_EXT_DIR}" || ! -d "${VSCODE_EXT_DIR}" ]]; then
    warn "extension: dossier des extensions VS Code introuvable (${VSCODE_EXT_DIR:-profil Windows non détecté}), VS Code non installé ?"
elif [[ "${CURRENT_OS}" == "wsl" ]]; then
    [[ -L "${ICONS_DST}" ]] && rm "${ICONS_DST}"
    if [[ -d "${ICONS_DST}" ]] && diff -rq "${ICONS_SRC}" "${ICONS_DST}" &>/dev/null; then
        info "extension: custom-icons → ${ICONS_DST} (copie déjà à jour)"
    else
        backup "${ICONS_DST}"
        cp -r "${ICONS_SRC}" "${ICONS_DST}"
        info "extension: custom-icons → ${ICONS_DST} (copie)"
    fi
else
    backup "${ICONS_DST}"
    ln -sfn "${ICONS_SRC}" "${ICONS_DST}"
    info "extension: custom-icons → ${ICONS_DST}"
fi

# ── Dépendances ──────────────────────────────────────────────────────────────

echo ""
echo "==> dépendances"
"${REPO_DIR}/install-deps.sh" --check || warn "installer ce qui manque : ./install-deps.sh"

echo ""
info "Terminé."
