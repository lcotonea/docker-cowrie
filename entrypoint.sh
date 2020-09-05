#!/bin/bash

cat ${COWRIE_HOME}/cowrie-git/etc-import/cowrie.cfg > ${COWRIE_HOME}/cowrie-git/etc/cowrie.cfg
cat ${COWRIE_HOME}/cowrie-git/etc-import/userdb > ${COWRIE_HOME}/cowrie-git/etc/userdb

cd ${COWRIE_HOME}
cowrie $@