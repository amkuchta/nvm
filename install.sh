
NVM_VERSION="1.1.3"
NVM_VERSION_V="v${NVM_VERSION}"

if [ -n "$NVM_TEST" ]; then
  NVM_TGZ_URL="https://github.com/jchip/nvm/archive/${NVM_VERSION_V}.tar.gz"
else
  NVM_TGZ_URL="https://registry.npmjs.org/@jchip/nvm/-/nvm-${NVM_VERSION}.tgz"
fi

if [ -z "${NVM_HOME}" ]; then
  export NVM_HOME="$HOME/nvm"
fi

function fetch() {
  curl=$(which curl)
  if [ "$?" == "0" ]; then
    curl --fail -L $1 -o $2
    return $?
  fi

  wget=$(which wget)
  if [ "$?" == "0" ]; then
    wget "$1" --output-document="$2"
    return $?
  fi

  echo "No curl or wget found"
  exit 1
}

function tmpdir() {
  if [ -n "$TMPDIR" ]; then
    echo "$TMPDIR"
  else
    echo "/tmp"
  fi
}

NODE_JS_ORG="https://nodejs.org"

function getLtsVersion() {
    NODE_JS_HTML="$(tmpdir)/nodejs.html"

    fetch $NODE_JS_ORG $NODE_JS_HTML

    local fv
    fv=$(egrep -o "Download[ 0-9\.]+LTS" "$NODE_JS_HTML" | egrep -o "[0-9\.]+")

    if [ -n "$fv" ]; then
      echo "v$fv"
    else
      echo "v10.16.0"
    fi
}

echo "Checking for latest node.js LTS from ${NODE_JS_ORG}"
DEFAULT_NODE_VERSION=$(getLtsVersion)

function getOs() {
  uname -s | tr "[:upper:]" "[:lower:]"
}

function getArch() {
  case $(uname -m) in
    x86_64)
      echo "x64"
      ;;
    i686 | i386)
      echo "x86"
      ;;
    *)
      uname -m | tr "[:upper:]" "[:lower:]"
      ;;
  esac
}

function fetchNodeJS() {
  local version
  version="$1"

  local nodejsMirror
  if [ -n "${NVM_NODEJS_ORG_MIRROR}" ]; then
    nodejsMirror="${NVM_NODEJS_ORG_MIRROR}"
  else
    nodejsMirror="https://nodejs.org/dist"
  fi

  local tgzFile
  tgzFile="node-${version}-$(getOs)-$(getArch).tar.gz"
  nodejsBinUrl="${nodejsMirror}/${version}/${tgzFile}"

  local cacheDir
  cacheDir="${NVM_CACHE}/${version}"
  mkdir -p "${cacheDir}"
  local destTgzFile
  destTgzFile="${cacheDir}/node.tgz"

  if [ ! -f "${destTgzFile}" ]; then
    echo "Fetching ${nodejsBinUrl}"

    if ! fetch "${nodejsBinUrl}" "${destTgzFile}"; then
      rm -rf "${cacheDir}"
    fi
  fi

  if [ -f "${destTgzFile}" ]; then
    tar xzf "${destTgzFile}" --strip=2 --directory "${NVM_HOME}" "*/bin/node"
  else
    echo "Unable to fetch ${nodejsBinUrl}"
    exit 1
  fi
}

NVM_CACHE="${NVM_HOME}/cache"
NVM_NODE="${NVM_HOME}/nodejs"
NVM_NODE_BIN="${NVM_HOME}/node"

function installNvm() {
  if [ ! -d "${NVM_CACHE}" ]; then
    mkdir -p "${NVM_CACHE}"
  fi

  local nvmDestTgzFile
  nvmDestTgzFile="${NVM_CACHE}/nvm-${NVM_VERSION_V}.tgz"

  echo "Fetching ${NVM_TGZ_URL}"
  fetch "${NVM_TGZ_URL}" "${nvmDestTgzFile}"

  local nvm_files
  nvm_files="$(tmpdir)/nvm_files.txt"
  cat >${nvm_files}<<EOF
*/bin
*/dist
*/package.json
EOF

  tar xzf "${nvmDestTgzFile}" --directory="${NVM_HOME}" --strip=1 --files-from="$nvm_files"
}

fetchNodeJS "${DEFAULT_NODE_VERSION}"

if [ -f "test.sh" ]; then
  source test.sh
else
  installNvm
fi

source "${NVM_HOME}/bin/nvm.sh"

function setBashRc() {
  BASH_RC="${HOME}/.bashrc"
  BASH_PROFILE="${HOME}/.bash_profile"

  local rcfile

  if [ -f "${BASH_RC}" ]; then
    rcfile="${BASH_RC}"
  else
    rcfile="${BASH_PROFILE}"
  fi

  if [ ! -f "${rcfile}" ]; then
    touch "${rcfile}"
  fi

  ${NVM_NODE_BIN} ${NVM_HOME}/bin/install_bashrc.js "${rcfile}"
}

setBashRc

nvm install $DEFAULT_NODE_VERSION
