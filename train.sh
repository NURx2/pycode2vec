#!/usr/bin/env bash
###########################################################
# The file is based on ./code2vec/preprocess.sh and ./code2vec/train.sh
###########################################################
# PREPROCESSING
###########################################################

. ./default.config

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --nthreads)
    NUM_THREADS="$2"
    shift # past argument
    shift # past value
    ;;
esac
done

${PYTHON} dataset_to_codefiles.py --chunks_dir ${CHUNKS_DIR}

mkdir -p data

echo "Extracting paths from validation set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${VAL_DIR} --output ${JAR_OUTPUP_FOLDER_VAL} \
  --maxL ${MAX_PATH_LENGTH} --maxW ${MAX_PATH_WIDTH} --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} \
  --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from validation set"
echo "Extracting paths from test set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${TEST_DIR} --output ${JAR_OUTPUP_FOLDER_TEST} \
  --maxL ${MAX_PATH_LENGTH} --maxW ${MAX_PATH_WIDTH} --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} \
  --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from test set"
echo "Extracting paths from training set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${TRAIN_DIR} --output ${JAR_OUTPUP_FOLDER_TRAIN} \
  --maxL ${MAX_PATH_LENGTH} --maxW ${MAX_PATH_WIDTH} --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} \
  --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from training set"

${PYTHON} filepaths_to_targets.py ${VAL_DATA_FILE} ${TEST_DATA_FILE} ${TRAIN_DATA_FILE}

echo "Creating histograms from the training data"
cat ${TRAIN_DATA_FILE} | cut -d' ' -f1 | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${TARGET_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f1,3 | tr ',' '\n' \
  | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${ORIGIN_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f2 \
  | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${PATH_HISTOGRAM_FILE}

${PYTHON} code2vec/preprocess.py --train_data ${TRAIN_DATA_FILE} --val_data ${VAL_DATA_FILE} \
  --max_contexts ${MAX_CONTEXTS} --word_vocab_size ${WORD_VOCAB_SIZE} --path_vocab_size ${PATH_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --word_histogram ${ORIGIN_HISTOGRAM_FILE} --output_name ${DATA_DIR}/data \
  --path_histogram ${PATH_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --test_data ${TEST_DATA_FILE}
    
# If all went well, the raw data files can be deleted, because preprocess.py creates new files 
# with truncated and padded number of paths for each example.
rm ${TARGET_HISTOGRAM_FILE} ${ORIGIN_HISTOGRAM_FILE} ${PATH_HISTOGRAM_FILE}

echo "### Preprocessing is done ###"

##########################################################
# TRAINING
##########################################################

mkdir -p ${MODEL_DIR} ${VECTORS_DIR}
${PYTHON} -u code2vec/code2vec.py --framework tensorflow --data ${DATA_DIR}/data --test ${VAL_DATA} \
  --save ${MODEL_DIR}/saved_model
