#!/usr/bin/env bash

. ./default.config

${PYTHON} -u code2vec/code2vec.py --framework tensorflow --load ${MODEL_DIR}/saved_model --test ${TEST_DATA} --export_code_vectors

${PYTHON} -u code2vec/code2vec.py --framework tensorflow --load ${MODEL_DIR}/saved_model --save_t2v ${TARGET_VECTORS_FILE_PATH}

rm -f log.txt keras_model_log.txt

cat ${TEST_DATA}.vectors > ${VECTORS_DIR}/${CODE_VECTORS_FILE}
