import argparse
import pandas as pd
import shutil
import os
from sklearn.model_selection import train_test_split

def create_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

parser = argparse.ArgumentParser()
parser.add_argument('--chunks_dir', dest='chunks_dir', type=str, required=True)
args = parser.parse_args()

df_train = pd.read_csv('datasets/train.csv', index_col=0)
df_test = pd.read_csv('datasets/test.csv', index_col=0)

df_train.sort_index(inplace=True)
df_test.sort_index(inplace=True)

df_train = df_train[df_train.groupby('target')['target'].transform('size') > 9]

print('\nTrain dataset target statistics:')
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

if os.path.exists(args.chunks_dir):
    shutil.rmtree(args.chunks_dir)

train_path = os.path.join(args.chunks_dir, 'train')
val_path = os.path.join(args.chunks_dir, 'val')
test_path = os.path.join(args.chunks_dir, 'test')

create_dir(train_path)
for i, code in X_train.items():
    print(code[1:-1], file=open(train_path + '/' + str(i) + '|' + y_train.loc[i] + '.py', 'w+'))

create_dir(val_path)
for i, code in X_test.items():
    print(code[1:-1], file=open(val_path + '/' + str(i) + '|' + y_test.loc[i] + '.py', 'w+'))

create_dir(test_path)
for i, code in df_test['code_block'].items():
    print(code[1:-1], file=open(test_path + '/' + str(i) + '|' + df_test['target'].loc[i] + '.py', 'w+'))
