#!/usr/bin/perl -s
# -------------------------------------------------------------
#   OBJECT ORIENTED VERSION
#       The MegaConector is a servers and connections handling.
#       MegaConector class variables , represents the main data
#       programm execution. Each Conector has a Server to
#       connect and handle the results and logs.
#       MegaConector manage the DB connection , servers db
#       queryes , multi-process execution , signals processing,
#       processes parametrization.
# -------------------------------------------------------------
#
#  VERSION 2 -
#       testing - 1.0.0 - everything is working
#
# -------------------------------------------------------------

sub INT_handler {
        print STDERR "\n{MEGA-C} SIGKILL RECEIVED\n";
        print STDERR "{MEGA-C} END.\n";
        exit(0);
}
### SET THE INTERRUPT HANDLER TO TERMINATE THE PROGRAM PROPERLY
$SIG{'INT'} = 'INT_handler';

###############################################################
package MegaConector;
###############################################################

use strict;
use IO::Handle;
use Switch;

#### CARGOS MIS MODULOS
use Object;
use Conector;
use Server;
use MC_ExpectManager;
use MC_Config;

@MegaConector::ISA = ("Object");

sub newHandler {

        #### POR DEFECTO SON 25 INSTANCIAS , AL AZAR
        my ($self) = { "instances" => 25 };

        bless $self, 'MegaConector';   # Tag object with pkg name
        return $self;
}

sub DESTROY { my ($self) = shift; return undef $self; }

### ----------------------------------------------------

sub init {
        my ($self)   = shift;

        $MegaConector::config = new MC_Config ();
        $MegaConector::conectores = ();
        $MegaConector::childs = ();

        my $Serv_hdl = Server->newHandler();
        @MegaConector::servers = @{ $Serv_hdl->getServers() };
        $self->loadConfig( $MegaConector::config );
}

sub loadConfig {
        my ($self) = shift;
        my ($config) = $_[0];
        $self->{'config'} = $config;

        ##### INICIALIZANDO LA CONFIGURACION DEL MEGACONECTOR
        if ( $config->{'instances'} ) {
                $self->{'instances'} = $config->{'instances'};
                if ( $self->{'instances'} > scalar(@MegaConector::servers) ) {
                        print "{MEGA-C} Config - Instances : Truncated to servers amount.\n";
                        $self->{'instances'} = scalar(@MegaConector::servers) ;
                }
        }
        print "{MEGA-C} Config - Instances : Using " . $self->{'instances'} . " simultaneous conections.\n";

        ##### LOGS DIRECTORY VALIDATION
        $self->{'log_dir'} = "logs_".`date '\''+%d-%m-%y_%H-%M-%S'\''`;
        chomp( $self->{'log_dir'} );

        if ( ! -d $self->{'log_dir'} ) {
                mkdir( $self->{'log_dir'} , 0750 )
                        or die "[ERROR ] - Can't create log directory ".$self->{'log_dir'}." : $!\n";
        }
        elsif ( ! -w $self->{'log_dir'} ) { die "[ERROR ] - Can't write on log directory ".$self->{'log_dir'}."\n"; }

        $MegaConector::config->{'log_dir'} = $self->{'log_dir'};
}


sub createLOGS {
        my ($self)      = shift;
        my ($curr_ins)  = $_[0];
        my ($out_file)  = "stdout_$curr_ins.log";
        my ($err_file)  = "stderr_$curr_ins.log";

	open (OUTPUT, ">$self->{'log_dir'}/$out_file" ) or die "[ERROR ] - Can't open OUTPUT : $!";
	open (ERROR , ">$self->{'log_dir'}/$err_file" ) or die "[ERROR ] - Can't open ERROR  : $!";
        open (CPERR, ">&STDERR");
        open (CPOUT, ">&STDOUT");

	STDOUT->fdopen( \*OUTPUT, 'w') or die $!;
	STDERR->fdopen( \*ERROR , 'w') or die $!;
}
sub restoreLOGS {
        my ($self)      = shift;
        close (OUTPUT) or die "[ERROR ] - Can't close OUTPUT : $!";
        close (ERROR)  or die "[ERROR ] - Can't close ERROR : $!";

        STDOUT->close();
        STDERR->close();

	STDOUT->fdopen( \*CPOUT, 'w') or die "Can't reopen STDOUT : $!";
	STDERR->fdopen( \*CPERR, 'w') or die "Can't reopen STDERR : $!";
}

sub createConnectors {
        my ($self) = shift;
        my ($server,$conector);
                        
        foreach $server (@MegaConector::servers) {
                print "{MEGA-C} >>>> Creating connector for server $server->{'hostname'}\n";
                $conector = $self->newConectorWith( $server );
                push @MegaConector::conectores , $conector ;
        }
}

sub runWithForks {
        my ($self) = shift;
        my ($server, $conector);
        my (@curr_connectors);
        my ($ins);

        $self->createConnectors();
        print "{MEGA-C} #### RUNNING ".$self->{"instances"}." instances\n";

        for ( $ins=0; $ins < $self->{"instances"}; $ins++ ){

                my $pid = fork();
                if ($pid) {
                        push @MegaConector::childs, $pid;
                } elsif ( $pid == 0 ) {
###################### EL HIJO-MEGACONECTOR
                        my $total = scalar(@MegaConector::conectores);
                        my $beg   = int( ($total*$ins) / $self->{"instances"} );
                        my $end   = int( ( ($total*($ins+1)) /$self->{"instances"} ) -1 );

                        #print "{MEGA-$ins} #### From conector : $beg to: $end recorriendo...\n";
                        @curr_connectors = @MegaConector::conectores[$beg..$end];

                        foreach $conector (@curr_connectors) {
                                $server = $conector->get("server");
                                print "{MEGA-$ins} #### Current server : ".$server->{"hostname"}."\n";
                                $self->createLOGS( $server->{"hostname"} );
                                print "{MEGA-$ins} >>>> Connecting ".$server->{'hostname'}."\n";
                                $conector->execute();
                                $self->restoreLOGS();
                                print "{MEGA-$ins} RESULT ".$server->{"hostname"}." : ".$conector->{"result"}."\n";
                        }
                        exit(0);
####################### FIN DEL PROCESO HIJO
                } else {
                        print STDERR "{MEGA-C} #### No se puede crear hijos\n!";
                }
        }
        # ESPERO QUE TODOS LOS CHILDS TERMINEN
        print "{MEGA-C} ESPERANDO HILOS\n";
        foreach (@MegaConector::childs) { waitpid($_, 0); }
        print "{MEGA-C} FIN. RECOLECCION FINALIZADA\n";
}

sub end { my ($self) = shift; return $self->DESTROY(); }

sub newConectorWith {
        my ($self) = shift;
        my ($server) = $_[0];

        return Conector::new(
                $server,
                $self->{'config'}
        );
}

sub runBatch {
        my ($self) = shift;
        my ($server, $conector);

        foreach $server ( @MegaConector::servers ) {
                print "$server->{'hostname'}\n";
                $conector = MegaConector->newConectorWith( $server );
                push @MegaConector::conectores , $conector ;
                $conector->execute();
        }
        exit 0 ;
}

###############################################################
package MAIN;
###############################################################

my ($MC_handler) = MegaConector::newHandler();

$MC_handler->init();
print "\n"; print "\n";
print "Se van a ejecutar los siguientes comandos :\n";
print "   \"$MegaConector::config->{'commands'}\"\n";
print "Se va a subir el script :\n";
print "   \"$MegaConector::config->{'filename'}\"\n";
print "Presione ENTER para continuar\n";
print "\n"; print "\n";
<STDIN>;
$MC_handler->runWithForks();
$MC_handler->end();

exit 0;

"1;"

__END__
