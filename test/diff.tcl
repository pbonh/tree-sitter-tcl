# Copyright (c) 2003 by Kevin B. Kenny.  All rights reserved.
# See the file,
# 'http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/tcllib/tcllib/license.terms'
# for terms and conditions of redistribution.

package require Tcl 8.0

namespace eval list { namespace export longestCommonSubsequence }

# Do a compatibility version of [lset] for pre-8.4 versions of Tcl.
# This version does not do multi-arg [lset]!

if { [package vcompare [package provide Tcl] 8.4] < 0 } {
    proc list::K { x y } { set x }
    proc list::lset { var index arg } {
        upvar 1 $var list
        set list [lreplace [K $list [set list {}]] $index $index $arg]
    }
}

# list::longestCommonSubsequence --
#
#       Computes the longest common subsequence of two lists.
#
# Parameters:
#       sequence1, sequence2 -- Two lists to compare.
#
# Results:
#       Returns a list of two lists of equal length. 
#       The first sublist is of indices into sequence1, and the
#       second sublist is of indices into sequence2.  Each corresponding
#       pair of indices corresponds to equal elements in the sequences;
#       the sequence returned is the longest possible.
#
# Side effects:
#       None.

proc list::longestCommonSubsequence { sequence1 sequence2 } {

    # Construct a set of equivalence classes of lines in file 2

    set index 0
    foreach string $sequence2 {
        lappend eqv($string) $index
        incr index
    }

    # K holds descriptions of the common subsequences.
    # Initially, there is one common subsequence of length 0,
    # with a fence saying that it includes line -1 of both files.
    # The maximum subsequence length is 0; position 0 of
    # K holds a fence carrying the line following the end
    # of both files.

    lappend K [list -1 -1 {}]
    lappend K [list [llength $sequence1] [llength $sequence2] {}]
    set k 0

    # Walk through the first file, letting i be the index of the line and
    # string be the line itself.

    set i 0
    foreach string $sequence1 {

        # Consider each possible corresponding index j in the second file.

        if { [info exists eqv($string)] } {

            # c is the candidate match most recently found, and r is the
            # length of the corresponding subsequence.
            
            set c [lindex $K 0]
            set r 0

            foreach j $eqv($string) {
                
                # Perform a binary search to find a candidate common
                # subsequence to which may be appended this match.
                
                set max $k
                set min $r
                set s [expr { $k + 1 }]
                while { $max >= $min } {
                    set mid [expr { ( $max + $min ) / 2 }]
                    set bmid [lindex [lindex $K $mid] 1]
                    if { $j == $bmid } {
                        break
                    } elseif { $j < $bmid } {
                        set max [expr {$mid - 1}]
                    } else {
                        set s $mid
                        set min [expr { $mid + 1 }]
                    }
                }

                # Go to the next match point if there is no suitable
                # candidate.

                if { $j == [lindex [lindex $K $mid] 1] || $s > $k} {
                    continue
                }
                
                # s is the sequence length of the longest sequence
                # to which this match point may be appended. Make
                # a new candidate match and store the old one in K
                # Set r to the length of the new candidate match.
                
                set newc [list $i $j [lindex $K $s]]
                lset K $r $c
                set c $newc
                set r [expr { $s + 1 }]
                
                # If we've extended the length of the longest match,
                # we're done; move the fence.

                if { $s >= $k } {
                    lappend K [lindex $K end]
                    incr k
                    break
                }
                
            }

            # Put the last candidate into the array

            lset K $r $c
            
        }
        
        incr i

    }

    set q [lindex $K $k]

    for { set i 0 } { $i < $k } {incr i } {
        lappend seta {}
        lappend setb {}
    }
    while { [lindex $q 0] >= 0 } {
        incr k -1
        lset seta $k [lindex $q 0]
        lset setb $k [lindex $q 1]
        set q [lindex $q 2]
    }

    return [list $seta $setb]
        
}

# MAIN PROGRAM
#
# Usage:
#       diff.tcl file1 file2
#
# Output:
#       Puts out a list of lines consisting of:
#               n1<TAB>n2<TAB>line
#
#       where n1 is a line number in the first file, and n2 is a line number in the second file.
#       The line is the text of the line.  If a line appears in the first file but not the second,
#       n2 is omitted, and conversely, if it appears in the second file but not the first, n1
#       is omitted.

# Open the files and read the lines into memory

set f1 [open [lindex $argv 0] r]
set lines1 [split [read $f1] \n]
close $f1
set f2 [open [lindex $argv 1] r]
set lines2 [split [read $f2] \n]
close $f2

set i 0
set j 0

foreach { x1 x2 } [list::longestCommonSubsequence $lines1 $lines2] {
    foreach p $x1 q $x2 {
        while { $i < $p } {
            set l [lindex $lines1 $i]
            puts "[incr i]\t\t$l"
        }
        while { $j < $q } {
            set m [lindex $lines2 $j]
            puts "\t[incr j]\t$m"
        }
        set l [lindex $lines1 $i]
        puts "[incr i]\t[incr j]\t$l"
    }
}
while { $i < [llength $lines1] } {
    set l [lindex $lines1 $i]
    puts "[incr i]\t\t$l"
}
while { $j < [llength $lines2] } {
    set m [lindex $lines2 $j]
    puts "\t[incr j]\t$m"
}

