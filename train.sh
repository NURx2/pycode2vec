#!/usr/bin/env bash
###########################################################
# The file is based on ./code2vec/preprocess.sh and ./code2vec/train.sh
###########################################################
# Change the following values to preprocess a new dataset.
# TRAIN_DIR, VAL_DIR and TEST_DIR should be paths to      
#   directories containing sub-directories with .py files
#   each of {TRAIN_DIR, VAL_DIR and TEST_DIR} should have sub-dirs,
#   and data will be extracted from .java files found in those sub-dirs).
# DATASET_NAME is just a name for the currently extracted 
#   dataset.                                              
# MAX_CONTEXTS is the number of contexts to keep for each 
#   method (by default 200).                              
# WORD_VOCAB_SIZE, PATH_VOCAB_SIZE, TARGET_VOCAB_SIZE -   
#   - the number of words, paths and target words to keep 
#   in the vocabulary (the top occurring words and paths will be kept). 
#   The default values are reasonable for a Tesla K80 GPU 
#   and newer (12 GB of board memory).
# NUM_THREADS - the number of parallel threads to use. It is 
#   recommended to use a multi-core machine for the preprocessing 
#   step and set this value to the number of cores.
# PYTHON - python3 interpreter alias.
###########################################################
# PREPROCESSING
###########################################################

NUM_THREADS=1
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

TRAIN_DIR=input_chunks/train
VAL_DIR=input_chunks/val
TEST_DIR=input_chunks/test

MAX_CONTEXTS=200
WORD_VOCAB_SIZE=50000
PATH_VOCAB_SIZE=50000
TARGET_VOCAB_SIZE=5000
PYTHON=python3
JAVA=java 

${PYTHON} dataset_to_codefiles.py --train_dir ${TRAIN_DIR} --val_dir ${VAL_DIR} --test_dir ${TEST_DIR}

JAR_OUTPUP_FOLDER_TRAIN=preprocessed_data/train
JAR_OUTPUP_FOLDER_VAL=preprocessed_data/val
JAR_OUTPUP_FOLDER_TEST=preprocessed_data/test
# check EXTRACT_JAR filepath if update astminer
EXTRACTOR_JAR=astminer/build/shadow/lib-0.6.jar

mkdir -p data

echo "Extracting paths from validation set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${VAL_DIR} --output ${JAR_OUTPUP_FOLDER_VAL} --maxL 8 --maxW 4 --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from validation set"
echo "Extracting paths from test set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${TEST_DIR} --output ${JAR_OUTPUP_FOLDER_TEST} --maxL 8 --maxW 4 --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from test set"
echo "Extracting paths from training set..."
${JAVA} -jar ${EXTRACTOR_JAR} code2vec --lang py --project ${TRAIN_DIR} --output ${JAR_OUTPUP_FOLDER_TRAIN} --maxL 8 --maxW 4 --maxContexts ${MAX_CONTEXTS} --maxTokens ${WORD_VOCAB_SIZE} --maxPaths ${PATH_VOCAB_SIZE}
echo "Finished extracting paths from training set"

PATH_CONTEXTS_FILE=py/path_contexts.csv
VAL_DATA_FILE=${JAR_OUTPUP_FOLDER_VAL}/${PATH_CONTEXTS_FILE}
TEST_DATA_FILE=${JAR_OUTPUP_FOLDER_TEST}/${PATH_CONTEXTS_FILE}
TRAIN_DATA_FILE=${JAR_OUTPUP_FOLDER_TRAIN}/${PATH_CONTEXTS_FILE}

${PYTHON} filepaths_to_targets.py ${VAL_DATA_FILE} ${TEST_DATA_FILE} ${TRAIN_DATA_FILE}

DATA_DIR=data
TARGET_HISTOGRAM_FILE=${DATA_DIR}/histo.tgt.c2v
ORIGIN_HISTOGRAM_FILE=${DATA_DIR}/histo.ori.c2v
PATH_HISTOGRAM_FILE=${DATA_DIR}/histo.path.c2v

echo "Creating histograms from the training data"
cat ${TRAIN_DATA_FILE} | cut -d' ' -f1 | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${TARGET_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f1,3 | tr ',' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${ORIGIN_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f2 | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${PATH_HISTOGRAM_FILE}

${PYTHON} code2vec/preprocess.py --train_data ${TRAIN_DATA_FILE} --val_data ${VAL_DATA_FILE} \
  --max_contexts ${MAX_CONTEXTS} --word_vocab_size ${WORD_VOCAB_SIZE} --path_vocab_size ${PATH_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --word_histogram ${ORIGIN_HISTOGRAM_FILE} --output_name ${DATA_DIR}/data \
  --path_histogram ${PATH_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --test_data ${TEST_DATA_FILE}
    
# If all went well, the raw data files can be deleted, because preprocess.py creates new files 
# with truncated and padded number of paths for each example.
rm ${TARGET_HISTOGRAM_FILE} ${ORIGIN_HISTOGRAM_FILE} ${PATH_HISTOGRAM_FILE}

##########################################################
# TRAINING
##########################################################

MODEL_NAME=current_model
MODEL_DIR=models/${MODEL_NAME}
VECTORS_DIR=vectors
CODE_VECTORS_FILE_PATH=${VECTORS_DIR}/code
TARGET_VECTORS_FILE_PATH=${VECTORS_DIR}/target_vectors.txt
VAL_DATA=${DATA_DIR}/data.val.c2v

mkdir -p ${MODEL_DIR} ${VECTORS_DIR}
python3 -u code2vec/code2vec.py --framework tensorflow --data ${DATA_DIR}/data --test ${VAL_DATA} --save ${MODEL_DIR}/saved_model \
  --export_code_vectors --save_t2v ${TARGET_VECTORS_FILE_PATH} --load ${MODEL_DIR}/saved_model

cat -n ${VAL_DATA}.vectors > ${VECTORS_DIR}/code_vectors.txt

rm -f log.txt keras_model_log.txt
