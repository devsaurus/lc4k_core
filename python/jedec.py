#--------------------------------------------------------------------
# Module        :   jedec
# Description   :   JEDEC file parsing
# Caveats       :
# Author        :   Chris Alfred
# Copyright (c) Chris Alfred
#
# Notes
#   JEDEC fuses
#       '0' = not fused (i.e. connected)
#       '1' = not fused (i.e. disconnected)
#--------------------------------------------------------------------
#
# https://github.com/ChrisEAlfred/galparse
#
# Arnim Laeuger 2022-04-25:
#   * Initialize fuse_data with information from F command
#   * Support multiple commands in a single line
#   * N command: Skip entire command line
#   * V command: Skip entire test vector line
#

#--------------------------------------------------------------------
# Imports
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# Class
#--------------------------------------------------------------------

class Jedec:

    def __init__(self):
        self._header_lines = []
        self.fuse_data = [0] * 0
        self.number_of_pins = 0
        self.number_of_fuses = 0
        self.default_fuse_value = -1
        self.checksum = '0000'
        self.debug = False

    #----------------------------------------------------------------
    # Private
    #----------------------------------------------------------------

    def _init_fuses(self):
        # Is all required information available?
        if self.number_of_fuses > 0 and self.default_fuse_value != -1:
            # Initialise data array to default value
            self.fuse_data = [self.default_fuse_value] * self.number_of_fuses

    #----------------------------------------------------------------
    # Public
    #----------------------------------------------------------------

    def load(self, file):

        got_asterisk = False
        in_header = True
        fuse_number = 0
        try:
            fp = open(file, 'r')
            for line in fp:

                # Strip CRLF and trailing spaces
                line = line.rstrip()

                # Remove leading * if present
                if line.startswith('*'):
                    if not got_asterisk:
                        got_asterisk = True
                        in_header = False
                    line = line[1:]

                # Remove trailing * if present
                if line.endswith('*'):
                    got_asterisk = True
                    line = line[:-1]

                words = line.split()

                if in_header:

                    # This is a header line
                    if self.debug:
                        print("Header: " + line)
                    self._header_lines.append(line)

                    if got_asterisk:
                        if self.debug:
                            print("[End of header]")
                        in_header = False


                if not in_header:

                    # Loop through all commands in a line
                    # Each command processing block is supposed to remove its words from the list
                    while len(words) > 0:
                        # Remove leading * on word
                        if words[0].startswith('*'):
                            words[0] = words[0][1:]
                        # Remove trailing * on word
                        if words[0].endswith('*'):
                            words[0] = words[0][:-1]

                        # Check keywords
                        if words[0].startswith('QP'):
                            # Number of pins
                            self.number_of_pins = int(words[0][2:])
                            words.pop(0)
                            if self.debug:
                                print('[Pins {}]'.format(self.number_of_pins))

                        elif words[0].startswith('F'):
                            # Default fuse value
                            self.default_fuse_value = words[0][1:]
                            words.pop(0)
                            if self.debug:
                                print('[Fuse default {}]'.format(self.default_fuse_value))

                            # Try to init fuses if all information is now available
                            self._init_fuses()

                        elif words[0].startswith('QF'):
                            # Number of fuses
                            self.number_of_fuses = int(words[0][2:])
                            words.pop(0)
                            if self.debug:
                                print('[Fuses {}]'.format(self.number_of_fuses))

                            # Try to init fuses if all information is now available
                            self._init_fuses()

                        elif words[0].startswith('C'):
                            # Checksum
                            self.checksum = words[0][1:]
                            words.pop(0)
                            if self.debug:
                                print('[Checksum {}]'.format(self.checksum))

                        elif words[0].startswith('L'):
                            # Fuse index header line
                            fuse_number = int(words[0][1:])
                            words.pop(0)
                            if self.debug:
                                print('[Fuse {}]'.format(fuse_number))

                            # The fuse data is read by the standalone block below

                        elif words[0].startswith('0') or words[0].startswith('1'):
                            # Fuse data on line by self
                            data = words[0]
                            words.pop(0)
                            if self.debug:
                                print('{:04d}: {}'.format(fuse_number, data))

                            # Copy fuse data to array
                            for v in data:
                                self.fuse_data[fuse_number] = v
                                fuse_number = fuse_number + 1

                        elif words[0].startswith('N'):
                            # Comment line
                            if self.debug:
                                print('[Comment {}]'.format(' '.join(words)))
                            words = []

                        elif words[0].startswith('V'):
                            # Test vector line
                            if self.debug:
                                print('[Test vector {}]'.format(' '.join(words)))
                            words = []

                        else:
                            words.pop(0)
                            pass

        finally:
            fp.close()
        
        return
