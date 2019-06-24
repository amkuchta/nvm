function nvm() {
  if [ -z $NVM_HOME ]; then
    NVM_HOME=~/nvm
  fi

  NVM_NODE=$NVM_HOME/node
  if [ ! -x $NVM_NODE ]; then
    NVM_NODE=$(which node)
  fi

  if [ ! -x $NVM_NODE ]; then
    echo "Can't locate default node executable";
    return 1
  fi

  echo "NVM node found at ${NVM_NODE}"

  $NVM_NODE $NVM_HOME/dist/nvm.js $*

  if [ -z $TMPDIR ]; then
    TMPDIR=/tmp
  fi

  if [ -f $TMPDIR/nvm_env.sh ]; then
    rm -rf $TMPDIR/nvm_envx.sh
    mv $TMPDIR/nvm_env.sh $TMPDIR/nvm_envx.sh
    source $TMPDIR/nvm_envx.sh
    rm -rf $TMPDIR/nvm_envx.sh
  fi
}