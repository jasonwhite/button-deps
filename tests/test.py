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
import fnmatch
import textwrap
import subprocess

class bcolors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ERROR = FAIL + BOLD + 'Error' + END

def check_positive(dirname, results, expected):
    """Checks the results with the expected results."""

    inputs  = (set(results['inputs']),  set(expected['inputs']))
    outputs = (set(results['outputs']), set(expected['outputs']))

    if not inputs[1].issubset(inputs[0]):
        print(bcolors.ERROR + ': Expected inputs are not a subset of the results.')
        print('       The following were not found in the results:')
        s = pprint.pformat(inputs[1] - inputs[0], width=1)
        print(textwrap.indent(s, '       '))
        print('       Instead, these were found:')
        s = pprint.pformat(inputs[0], width=1)
        print(textwrap.indent(s, '       '))
        return False

    if not outputs[1].issubset(outputs[0]):
        print(bcolors.ERROR + ': Expected outputs are not a subset of the results')
        print('       The following were not found in the results:')
        s = pprint.pformat(outputs[1] - outputs[0], width=1)
        print(textwrap.indent(s, '       '))
        print('       Instead, these were found:')
        s = pprint.pformat(outputs[0], width=1)
        print(textwrap.indent(s, '       '))
        return False

    missing = [p for p in (os.path.join(dirname, p) for p in outputs[0])
                if not os.path.exists(p)]

    if missing:
        print(bcolors.ERROR + ': Result outputs missing from file system:')
        pprint.pprint(missing)
        return False

    return True

def check_negative(dirname, results, expected):
    """Checks the results with the expected results."""

    inputs  = (set(results['inputs']),  set(expected['!inputs']))
    outputs = (set(results['outputs']), set(expected['!outputs']))

    if not inputs[1].isdisjoint(inputs[0]):
        print(bcolors.ERROR + ': Found inputs that should not exist:')
        s = pprint.pformat(inputs[1] & inputs[1], width=1)
        print(textwrap.indent(s, '       '))
        return False

    if not outputs[1].isdisjoint(outputs[0]):
        print(bcolors.ERROR + ': Found outputs that should not exist:')
        s = pprint.pformat(outputs[1] & outputs[1], width=1)
        print(textwrap.indent(s, '       '))
        return False

    existing = [p for p in (os.path.join(dirname, p) for p in outputs[1])
                if os.path.exists(p)]

    if existing:
        print(bcolors.ERROR + ': Outputs exist on from file system, but should not:')
        pprint.pprint(existing)
        return False

    return True

def cleanup(dirname, outputs):
    """Deletes the expected outputs."""
    for output in outputs:
        try:
            os.remove(os.path.join(dirname, output))
        except OSError:
            pass

def test(bbdeps, path):
    """Runs a single test.

    Compares the results with the expected results.
    """
    dirname = os.path.dirname(path)

    name, _ = os.path.splitext(path)

    print(bcolors.HEADER + ":: Test '{}'...".format(name) + bcolors.END)

    testcase = None
    with open(path) as f:
        testcase = json.load(f)

    args = [bbdeps, '--json', os.path.abspath('results.json'), '--'] + testcase['command']

    output = None
    try:
        output = subprocess.check_output(args, cwd=dirname)
    except subprocess.CalledProcessError as e:
        print(e.output)
        return False

    results = None
    with open('results.json') as f:
        results = json.load(f)

    success = check_positive(dirname, results, testcase) and \
              check_negative(dirname, results, testcase)

    if not success:
        print("These dependencies were reported:")
        pprint.pprint(results)

    cleanup(dirname, results['outputs'])

    return success

def find_tests(top='.'):
    for root, dirs, files in os.walk(top):
        for f in files:
            if fnmatch.fnmatch(f, 'test.*.json'):
                yield os.path.join(root, f)

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.realpath(__file__))
    os.chdir(script_dir)

    tests = find_tests()

    bbdeps = os.path.abspath('../bbdeps')

    success = 0
    total = 0
    for t in tests:
        total += 1
        if test(bbdeps, t):
            success += 1
        else:
            print(bcolors.FAIL + bcolors.BOLD + ' - TEST FAILED' + bcolors.END)

    os.remove('results.json')

    color = bcolors.OKGREEN if success == total else bcolors.FAIL

    print(color + bcolors.BOLD + ':: Summary: {}/{} ({:.0%}) tests passed'
            .format(success, total, success/total) + bcolors.END)

    if success < total:
        sys.exit(1)
