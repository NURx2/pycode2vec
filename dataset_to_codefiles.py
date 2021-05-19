import argparse
import pandas as pd
import shutil
import os
from sklearn.model_selection import train_test_split

def clear_dir(path):
    for filename in os.listdir(path):
        file_path = os.path.join(path, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print('Failed to delete %s. Reason: %s' % (file_path, e))

parser = argparse.ArgumentParser()
parser.add_argument('--train_dir', dest='train_dir', type=str, required=True)
parser.add_argument('--val_dir', dest='val_dir', type=str)
parser.add_argument('--test_dir', dest='test_dir', type=str)
args = parser.parse_args()

df_train = pd.read_csv('datasets/train.csv', index_col=0)
df_test = pd.read_csv('datasets/test.csv', index_col=0)

df_train.sort_index(inplace=True)
df_test.sort_index(inplace=True)

df_train = df_train[df_train.groupby('target')['target'].transform('size') > 9]

print('\nTrain ataset target statistics:')
print(df_train['target'].value_counts())    

print('\nTest dataset target statistics:')
print(df_test['target'].value_counts())    

X_train, X_test, y_train, y_test = train_test_split(
    df_train['code_block'], 
    df_train['target'], 
    test_size=0.1, 
    random_state=42,
    stratify=df_train['target'].tolist()
)

clear_dir(args.train_dir + '/')
for i, code in X_train.items():
    print(code[1:-1], file=open(args.train_dir + '/' + str(i) + '|' + y_train.loc[i] + '.py', 'w+'))

clear_dir(args.val_dir + '/')
for i, code in X_test.items():
    print(code[1:-1], file=open(args.val_dir + '/' + str(i) + '|' + y_test.loc[i] + '.py', 'w+'))

clear_dir(args.test_dir + '/')
for i, code in df_test['code_block'].items():
    print(code[1:-1], file=open(args.test_dir + '/' + str(i) + '|' + df_test['target'].loc[i] + '.py', 'w+'))
