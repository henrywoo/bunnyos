#!/usr/bin/python
# -*- coding: utf-8 -*-
# workable for python 2.4

import os
import sys

__author__ = 'Anderson Pierre Cardoso; Simon Wu Fuheng'

file_extension = '.asm'

license_notice = """;The BunnyOS
;Copyright (C) 2011 WuFuheng@gmail.com, Singapore
;
;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
"""

def prepend_license(file_path):
    """
    prepends the license notice into a file
    """
    print 'adding license to file: %s'%file_path
    #sys.exit()
    f = open(file_path, 'r+')
    old = f.read()
    f.seek(0)
    f.write(license_notice + old)
    f.close()
    """with open(file_path, 'r+') as f: # python 2.5+
        old = f.read()
        f.seek(0)
        f.write(license_notice + old)"""

def path_walker(raiz):
    for root,dirs,files in os.walk(raiz):
        #sys.exit()
        if root.find('.svn') == -1:
                print root, dirs, files
                [prepend_license(os.path.join(root,f)) for f in files if f.endswith(file_extension)]
    print 'finished path walking =]'


if __name__=='__main__':
    if len(sys.argv) < 2 or not os.path.isdir(sys.argv[1]):
        print >> sys.stderr, '\nOps, pass a valid root folder (of your project) as argument'
        sys.exit()

    raiz = os.path.join(os.getcwd(), sys.argv[1])
    print 'root folder is %s'%(raiz)

    path_walker(raiz)
