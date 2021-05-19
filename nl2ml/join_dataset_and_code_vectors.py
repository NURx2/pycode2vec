import pandas as pd

res_df = pd.read_csv('../vectors/code_vectors.txt', header=None, sep=' ')
data = pd.read_csv('../datasets/test.csv', index_col=0)

data.sort_index(inplace=True)

res_df['code_block'] = data['code_block'].reset_index(drop=True)
res_df['target'] = data['target'].reset_index(drop=True)

res_df.to_csv('result.csv')
