import sys
import os.path as op
from distutils.sysconfig import get_python_lib

lib_prefix = sys.argv[1]
py3_sitearch = get_python_lib(1, 0)

common_prefix = op.commonprefix([lib_prefix, py3_sitearch])

if common_prefix != lib_prefix:
    print('py3_sitearch is not inside the installation lib prefix!')
    sys.exit(1)

print(op.relpath(py3_sitearch, lib_prefix))
