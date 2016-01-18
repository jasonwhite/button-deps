#!/usr/bin/env python3

# Copyright (c) Jason White. MIT license.
#
# Description:
# Runs all tests.

import os
import sys
import json
import glob
import pprint
import textwrap
import subprocess

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ERROR = FAIL + BOLD + 'Error' + END

def results(f):
    """Parses the given results file and returns the inputs and outputs."""
    data = json.load(f)
    return set(data['inputs']), set(data['outputs'])

def test(bbdeps, path):
    """Runs a single test.

    Compares the results with the expected results.
    """
    dirname = os.path.dirname(path)

    name, _ = os.path.splitext(path)

    print(bcolors.HEADER + bcolors.BOLD + "Running test '{}'...".format(name) + bcolors.END)

    t = None
    with open(path) as f:
        t = json.load(f)

    args = [bbdeps, '--json', os.path.abspath('results.json'), '--'] + t['command']

    retcode = subprocess.call(args, cwd=dirname)

    if retcode != 0:
        return False

    results = None
    with open('results.json') as f:
        results = json.load(f)

    result_inputs = set(results['inputs'])
    result_outputs = set(results['outputs'])

    expected_inputs = set(t['inputs'])
    expected_outputs = set(t['outputs'])

    if not expected_inputs.issubset(result_inputs):
        print(bcolors.ERROR + ': Expected inputs are not a subset of the results.')
        print('       The following were not found in the results:')
        s = pprint.pformat(expected_inputs - result_inputs, width=1)
        print(textwrap.indent(s, '       '))
        return False

    if not expected_outputs.issubset(result_outputs):
        print(bcolors.ERROR + ': Expected outputs are not a subset of the results')
        print('       The following were not found in the results:')
        s = pprint.pformat(expected_outputs - result_outputs, width=1)
        print(textwrap.indent(s, '       '))
        return False

    return True

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.realpath(__file__))
    os.chdir(script_dir)
    tests = glob.glob('*/**/*.test.json', recursive=True)

    bbdeps = os.path.abspath('../bbdeps')

    success = 0
    total = 0
    for t in tests:
        total += 1
        if test(bbdeps, t):
            success += 1

    os.remove('results.json')

    print('Summary: {}/{} tests passed'.format(success, total))

    if success < total:
        sys.exit(1)
