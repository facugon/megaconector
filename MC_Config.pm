#!/usr/bin/perl -s

###############################################################
package MC_Config;
###############################################################

use strict;
use Object;

@MC_Config::ISA = ("Object");

sub new {

        my ($config_file) = "mega.conf";
        my ($self) = {
                "file" => $config_file ,
        };

        bless $self, 'MC_Config';   # Tag object with pkg name
        $self->get_config();
        $self->validate();
        return $self;
}

sub get_config {
        my ($self) = shift;
        my ($line) = undef;

        open(CONFIG, $self->{'file'} ) or
            die "[CONFIG] ERROR - No se pudo abrir el archivo de configuracion: $!";

        while (<CONFIG>) {
                $line = $_;
                ## CHEQUEO LINES VACIAS Y LINEAS CON COMENTARIO
                ## SI LA LINEA ES VACIA , USANDO REGEXP NO NECESITO QUITAR EL \n
                chomp($line); # pero por las dudas ...
                if ( $line !~ m/^#/ and $line !~ m/^\s*$/ and $line =~ m/=/ ) {
                        my @params = split( /\=/, $line, 2 );
                        $self->{@params[0]} = @params[1];
                }
        }
}

sub validate {

        ##### LOGS DIRECTORY VALIDATION
        #        if ( $config->{'log_dir'} ) { $self->{'log_dir'} = $config->{'log_dir'}; }
        #                else { $self->{'log_dir'} = "./logs"; }
        #
        #                        if ( ! -d $self->{'log_dir'} ) { mkdir( $self->{'log_dir'} , 0755 ) or die "[ERROR ] - Can't create log directory ".$self->{'log_dir'}." : $!\n"; }
        #                                elsif ( ! -w $self->{'log_dir'} ) { die "[ERROR ] - Can't write on log directory ".$self->{'log_dir'}."\n"; }
        #


}

"1;"
__END__
