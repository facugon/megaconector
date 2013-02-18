#!/usr/bin/perl -s
#########################
#
#   CONVIERTE TODOS LOS \n
#   DE CADA ARCHIVO EN ; PARA
#   PODER ABRIR CON EXEL.
#   CREA UNA LINEA POR ARCHIVO
#

if ( ! $dir ) { print "IMBECHIL ! No se especificaron archivos. use : repoToCSV.pl -dir='Path_to_files'\n"; exit; }

if ( ! -e $dir ) { print "IMBACHIL ! $dir no existe\n"; exit; }

open(WRITE,">./resultado.csv");

my @data=`ls -1 $dir/*_audit.log`;

foreach $cur (@data) {
        $content = `cat $cur`;
        $content =~ s/\n/;/g ;
        print WRITE $content."\n";
}

exit;
