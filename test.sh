[ -z $NVM_HOME ] && NVM_HOME=$HOME/nvm
mkdir -p $NVM_HOME/bin
mkdir -p $NVM_HOME/dist
cp bin/nvm.sh $NVM_HOME/bin
cp dist/nvm.js $NVM_HOME/dist