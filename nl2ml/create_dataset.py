import pandas as pd

data = pd.read_csv('data.csv')
graph = pd.read_csv('graph.csv')

res_dataset = data.merge(graph, left_on='graph_vertex_id', right_on='id')[['code_block', 'graph_vertex_subclass']]
res_dataset['target'] = res_dataset['graph_vertex_subclass'].apply(lambda s: s.replace('_', ''))
res_dataset.drop(columns='graph_vertex_subclass', inplace=True)

res_dataset.to_csv('../dataset.csv')
