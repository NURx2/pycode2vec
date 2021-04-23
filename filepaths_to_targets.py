import argparse

parser = argparse.ArgumentParser()
parser.add_argument('paths_list', nargs='+', type=str)

for p in parser.parse_args().paths_list:
    with open(p) as path_context_file:
    	content = path_context_file.readlines()
    with open(p, 'w') as path_context_file:
    	path_context_file.writelines(
    		list(map(lambda s: s[s.index('|')+1:].replace('.py', ''), content))
    	)
