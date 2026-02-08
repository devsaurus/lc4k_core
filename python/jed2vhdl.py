#--------------------------------------------------------------------
#
# jed2vhdl.py <jed file>
#
# Convert a .jed file into a std_logic_vector that's suitable for
# the jedecmap generic. The vector is printed to stdout.
#
# Core functionality is taken from Chris Alfred's suite at
#   https://github.com/ChrisEAlfred/galparse
#
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Imports
#--------------------------------------------------------------------

# System
import sys
import os

# local
import jedec

#--------------------------------------------------------------------
# Private
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Public - Main
#--------------------------------------------------------------------

if __name__ == '__main__':

    jedec_file = sys.argv[1]
    max_fnum = int(sys.argv[2])
    bare = False
    if len(sys.argv) >= 4:
        if sys.argv[3] == '-b':
            bare = True

    # Load the fuse data
    jedec = jedec.Jedec()
    jedec.load(jedec_file)

    # Print fuse map as VHDL std_logic_vector
    # max_fnum bits per line, '&' concatenation
    fnum = 0
    l = ''
    first = True
    for f in jedec.fuse_data:
        if fnum == 0:
            if first:
                first = False
            else:
                print(' &' if not bare else '')
            if not bare:
                l += '"'

        l += f
        fnum += 1
        if fnum == max_fnum:
            if not bare:
                l += '"'
            print(l, end='')
            l = ''
            fnum = 0

    if fnum > 0:
        if not bare:
            l += '"'
        print(l)
    else:
        print()

