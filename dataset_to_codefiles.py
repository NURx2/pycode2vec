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

df = pd.read_csv('dataset.csv')

df = df[df.groupby('target')['target'].transform('size') > 5]

print('Dataset target statistics:')
print(df['target'].value_counts())

X_train, X_test, y_train, y_test = train_test_split(
    df['code_block'], 
    df['target'], 
    test_size=0.2, 
    random_state=42,
    stratify=df['target'].tolist()
)

clear_dir(args.train_dir + '/')
for i, code in X_train.items():
    print(code[1:-1], file=open(args.train_dir + '/' + str(i) + '|' + y_train.loc[i] + '.py', 'w+'))

clear_dir(args.val_dir + '/')
for i, code in X_test.items():
    print(code[1:-1], file=open(args.val_dir + '/' + str(i) + '|' + y_test.loc[i] + '.py', 'w+'))
