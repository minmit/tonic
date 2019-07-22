import os, sys

def insertLibPath():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    lib_dir = os.path.join(script_dir, "./lib")
    sys.path.insert(0, lib_dir)

insertLibPath()