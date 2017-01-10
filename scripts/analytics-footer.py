#!/usr/bin/env python
"""
Filename: ensure-analytics.py
Description: Ensures the correct Google Analytics tracking pixel is at the
  footer of each document. This document can be found at scripts/analytics.txt
  It looks like this:

::

    <!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/ANALYTICS_ID/SITE/ORG/PROJECT/PATH?pixel)]() <!-- END ANALYTICS -->

With ANALYTICS_ID and PROJECT/PATH set to the correct values for a given document.
    
"""

import os

# Please keep this to one line.
analytics_str = "<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/ANALYTICS_ID/SITE/ORG/PROJECT/PATH?pixel)]() <!-- END ANALYTICS -->"

# All of this data will be written to the footer
analytics_id = 'UA-42684979-9'
org = 'coreos'
project = 'docs'
site = 'github.com'

# Recursively iterate over all files in this directory
for root, dirs, fnames in os.walk('.'):
    for fname in fnames:
        # Only operate on markdown files
        if fname.endswith('.md'):
            # Set current doc to a variable for convenience
            curr_doc = os.path.join(root, fname)

            # This ``if root is not '.' else fname`` business is to avoid an edgecase which results in 
            # urls like '[...]//README.md' and '[...]//CONTRIBUTING.md' in the root of the repo.
            filepath = '/'.join(root.split('/')[1:]) + '/' + fname if root is not '.' else fname

            footer = analytics_str.replace('ANALYTICS_ID', analytics_id) \
                                  .replace('SITE', site) \
                                  .replace('ORG', org) \
                                  .replace('PROJECT', project) \
                                  .replace('PATH', filepath)

            # Open the file. We will either:
            # - Add the footer
            # - Update the footer
            with open(curr_doc, 'r+') as f:
                f_arr = f.readlines()
                f_str = ''.join(f_arr)
                # File has bad footer
                if f_arr[-1] != footer:
                    # Incorrect footer
                    if f_arr[-1].endswith('<!-- END ANALYTICS -->'):
                        f_arr[-1] = footer
                        f.seek(0)
                        f.write(''.join(f_arr))
                    # No footer
                    elif f_arr[-1] != footer:
                        f.write('\n' + footer)

print('All documents updated with analytics.')
