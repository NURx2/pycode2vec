import pandas as pd

res_df = pd.read_csv('../vectors/code_vectors.txt', header=None, sep=' ')  # ../
filepaths = pd.read_csv('../data/ordered_test_files.txt', names=['filepath'])
codeblocks_to_filepaths = pd.read_csv('test_codeblocks_to_filepaths.csv')
data = (
	pd
	.read_csv('../datasets/test.csv', index_col=0)
	.drop_duplicates(subset=['code_block'])
)[['code_block', 'target']]

print('Code vectors shape: ', res_df.shape)
print('Test csv shape: ', data.shape)
print('Filepaths shape: ', filepaths.shape)
print('Codeblocks to filepaths shape: ', codeblocks_to_filepaths.shape)

if data.shape[0] != res_df.shape[0]:
	raise AssertionError('Shapes are different!')

res_df = (
	pd
	.concat([res_df, filepaths], axis=1)
	.merge(codeblocks_to_filepaths, on='filepath')
	.merge(data, on='code_block')
)

print('Result shape: ', res_df.shape)

res_df.to_csv('result.csv')
