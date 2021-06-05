import argparse

parser = argparse.ArgumentParser()
parser.add_argument('paths_list', nargs='+', type=str)
paths_list = parser.parse_args().paths_list

for p in paths_list:
    with open(p) as path_context_file:
        content = path_context_file.readlines()
    if p.find('test') != -1:  # TODO: remove the dirty hack
        filenames_container_path = 'data/ordered_test_files.txt'  # TODO: get data folder from upper level
        with open(filenames_container_path, 'w+') as filenames_container:
            filenames_container.writelines(
                list(map(lambda s: s[:s.find('.py')+3] + '\n', content))
            )
    print(content, file=open(p[:-4] + '_original.csv', 'w+'))
    with open(p, 'w') as path_context_file:
        path_context_file.writelines(
            list(map(lambda s: s[s.index('|')+1:].replace('.py', ''), content))
        )
