#!/usr/bin/env bash

. ./default.config

${PYTHON} dataset_to_codefiles.py --chunks_dir ${CHUNKS_DIR}

echo "Extracting paths from test set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${TEST_DIR} --output ${JAR_OUTPUP_FOLDER_TEST} \
  --maxL ${MAX_PATH_LENGTH} --maxW ${MAX_PATH_WIDTH} --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} \
  --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from test set"

${PYTHON} filepaths_to_targets.py ${TEST_DATA_FILE}

${PYTHON} code2vec/preprocess.py --train_data ${TRAIN_DATA_FILE} --val_data ${VAL_DATA_FILE} \
  --max_contexts ${MAX_CONTEXTS} --word_vocab_size ${WORD_VOCAB_SIZE} --path_vocab_size ${PATH_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --word_histogram ${ORIGIN_HISTOGRAM_FILE} --output_name ${DATA_DIR}/data \
  --path_histogram ${PATH_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --test_data ${TEST_DATA_FILE}

echo "### Preprocessing is done ###"

${PYTHON} -u code2vec/code2vec.py --framework tensorflow --load ${MODEL_DIR}/saved_model_iter --test ${TEST_DATA} --export_code_vectors

${PYTHON} -u code2vec/code2vec.py --framework tensorflow --load ${MODEL_DIR}/saved_model_iter --save_t2v ${TARGET_VECTORS_FILE_PATH}

rm -f log.txt keras_model_log.txt

cat ${TEST_DATA}.vectors > ${VECTORS_DIR}/${CODE_VECTORS_FILE}

cd nl2ml

${PYTHON} join_dataset_and_code_vectors.py
