import sys, os, glob
from datetime import datetime
from distutils.dir_util import copy_tree

def clear(src):
    for filename in glob.glob(src + '/**/*.log'):
        print('file cleared: ' + filename)
        with open(filename, 'w') as f:
            f.write('')

src_dir = sys.argv[1]
dest_dir_base = sys.argv[2]
dest_dir = dest_dir_base + '/' + datetime.today().strftime('%Y-%m-%d')

execute = 0

if os.path.exists(src_dir) and os.path.isdir(src_dir):
    if os.listdir(src_dir):
        if os.path.exists(dest_dir) and os.path.isdir(dest_dir):
            if not os.listdir(dest_dir):
                execute = 1
            else:
                execute = 0
        else:
            execute = 1


if execute == 1:
    print('running (dest=' + dest_dir + ')...')
    copy_tree(src_dir, dest_dir)
    clear(src_dir)
else:
    print('skipping (dest=' + dest_dir + ')...')
