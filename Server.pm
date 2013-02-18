#!/usr/bin/perl -s
# -------------------------------------------------------------

###############################################################
package Server;
###############################################################

use strict;
use DBI;
use Object;

@Server::ISA = ("Object");
my ($version) = "2";

### CLASS DATABASE HANDLER , TO GET ALL SERVERS REQUIRED OBJECTS AND INTANTIATE THEM
sub newHandler {
        my ($self) = {};
        bless $self, 'Server';   # Tag object with pkg name
        return $self;
}

sub new {
        # INITIALIZE SERVER 
        my ($host, $ip, $user, $pass1, $pass2) = @_;
        my ($self) = {
                "ip"        => $ip    ,
                "user"      => $user  ,
                "passwd"    => $pass1 ,
                "hostname"  => $host  ,
                "newpasswd" => $pass2 ,
        };

        bless $self, 'Server';   # Tag object with pkg name
        if ( $self->validateParameters() == 1 ) {
                return undef $self;
        }
        return $self;
}

sub loadConfig {
        my ($self) = shift;
        my ($config) = $MegaConector::config ;

        if ( ! $config->{'email'} ) {
                print "[SERVER] ConfigERROR - No e-mail provided.\n";
                exit 1;
        }
        $self->{'email'} = $config->{'email'};

        ##### NO ESTA VALIDADO , SI NO ESTA EN EL CONFIG SE ROMPE TO-DOOOOO !!!!
        $self->{'db_user'} = $config->{'db_user'};
        $self->{'db_pass'} = $config->{'db_pass'};
        $self->{'db_host'} = $config->{'db_host'};
        $self->{'db_name'} = $config->{'db_name'};

        ##### COMO PARAMETRIZAR LA CONSULTA?
        $self->{'db_field'} = $config->{'db_field'};
        $self->{'db_value'} = $config->{'db_value'};

        ##### CARGO EL ARCHIVO DE SERVIDORES SI EXISTE
        $self->{'hostsfile'} = $config->{'hostsfile'};
        $self->{'newpasswd'} = $config->{'newpasswd'};

        return 0;
}

sub newServerWith {
        my ($self) = shift;
        my (@serv_data) = @_;
        my ($server) = undef;

        print STDERR "[SERVER] >>>> Creating server ".$serv_data[0]."\n";
        if ( ! $serv_data[2] or ! $serv_data[3] ) {
                print STDERR "[SERROR] >>>>>> No password or no user for server ".$serv_data[0]."\n";
        } else {

                $server = Server::new(
                        $serv_data[0], # HOSTNAME
                        $serv_data[1], # IP
                        $serv_data[2], # USER
                        $serv_data[3], # PASSWD
                        $self->{'newpasswd'}, # NEW PASSWD
                );
                print STDERR  "[SERVER] >>>> DONE. \n";
        }
        return $server;
}

sub DESTROY {
        my ($self) = shift;
        return undef $self;
}
sub validateParameters {
        my ($self) = shift;
        if ( ! $self->{"user"}      ){ print STDERR "[SERVER] >>>> No user. Exiting\n"; exit 1; }
        if ( ! $self->{"passwd"}    ){ print STDERR "[SERVER] >>>> No password. Exiting\n"; exit 1; }
        if ( ! $self->{"newpasswd"} ){ print STDERR "[SERVER] >>>> No new password to use. Will not be changed the password if requested.\n"; }
        if ( ! $self->{"hostname"}  ){ print STDERR "[SERVER] >>>> No hostname to connect. Exiting\n"; exit 1; }
        if ( ! $self->{"ip"}        ){ print STDERR "[SERVER] >>>> No ip to connect. Will try to connect with the hostname\n"; }
        return 0;
}

sub dbHandler {
        my ($self)  = shift;
        return DBI->connect( 
                'DBI:mysql:'.$self->{'db_name'}.';host='.$self->{'db_host'} ,
                $self->{'db_user'} ,
                $self->{'db_pass'} ) ||
            die "Could not connect to database: $DBI::errstr";
}

sub getUserIDWithDBH {
        my ($self)  = shift;
        my ($dbh)   = $_[0];
        my ($query) = $dbh->prepare("SELECT `id` FROM `users` WHERE `email` LIKE '". $self->{'email'} ."'");
        $query->execute();
        return $query->fetchrow_array();
}

sub getServersBy {
        my ($self) = shift;
        my ($field,$value) = @_;
        my (@result,@servers) = undef;

        my ($dbh)     = $self->dbHandler();
        my ($user_id) = $self->getUserIDWithDBH( $dbh );

        my ($query) = $dbh->prepare('
                SELECT 
                    S.hostname AS host, S.ip AS ip,
                    A.user AS user, A.passwd AS passwd
                FROM
                    acc_server AS S, acc_acceso AS A
                WHERE
                    S.'.$field.' LIKE \''.$value.'\' AND S.id=A.serv_id AND A.user_id=\''. $user_id .'\''
        );
        $query->execute();

        while ( @result = $query->fetchrow_array() ) {
            push @servers, [@result] ; ### GUARDO LA REFERENCIA A LOS DATOS DEL SERVER
        }

        $dbh->disconnect();
        return @servers;
}

sub getServers {
        my ($self) = shift;

        $self->loadConfig();

        if ( $self->{'hostsfile'} ) {
                print "[SERVER] Loading servers from HOSTS FILE ".
                    $self->{'hostsfile'}."\n";
                return $self->getServers_hostnamesFromFile();
        }
        print "[SERVER] Loading servers all from DATABASE filter\n";
        return $self->getServers_allFromDB();
}

sub getServers_allFromDB {
        my ($self) = shift;
        my (@result, $serv_data, $server) = undef;
        my (@servers) = ();

        @result = $self->getServersBy( $self->{'db_field'} , $self->{'db_value'});
        foreach $serv_data ( @result ) {
                if ( $server = $self->newServerWith( @{$serv_data} ) ) {
                        push @servers, $server;
                }
        }
        return \@servers;

}

sub getServers_hostnamesFromFile {
        my ($self) = shift;
        my (@result, $serv_data, $server, $hostname) = undef;
        my (@hostssss, @servers) = ();

        open( FILE, $self->{'hostsfile'} ) 
                or die ("[SERVER] Unable to found ".
                $self->{'hostsfile'}." in current directory!\n");
        @hostssss = <FILE>;
        close(FILE);

        foreach $hostname (@hostssss) {
                chomp($hostname);
                @result = $self->getServersBy('hostname',$hostname);
                if ( scalar(@result) == 1 ) {
                        $serv_data = shift (@result); ### GET FIRST AND ONLY ELEMENT
                        if ( $server = $self->newServerWith( @{$serv_data} ) ) {
                                push @servers, $server;
                        }
                } else {
                        print "[SERVER] ERROR - query result error for '$hostname'!\n";
                        print "[SERVER] Name ignored\n";
                }
        }
        return \@servers;
}

sub newpasswdIsDefined { my ($self) = shift; return defined $self->get("newpasswd"); }
sub setPasswdWithNewPasswd {
        my ($self) = shift;
        $self->{'passwd'} = $self->{'newpasswd'};
        return 0;
}

"1;"
__END__
