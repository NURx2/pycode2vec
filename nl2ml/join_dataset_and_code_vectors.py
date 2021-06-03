import pandas as pd

res_df = pd.read_csv('../vectors/code_vectors.txt', header=None, sep=' ')
data = pd.read_csv('../datasets/test.csv', index_col=0)

print('Code vectors shape: ', res_df.shape)
print('Test csv shape: ', data.shape)

if data.shape[0] != res_df.shape[0]:
	raise AssertionError('Shapes are different!')

res_df['code_block'] = data['code_block'].reset_index(drop=True)
res_df['target'] = data['target'].reset_index(drop=True)

res_df.to_csv('result.csv')
