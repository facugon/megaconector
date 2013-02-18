#!/usr/bin/perl -s
# -------------------------------------------------------------

###############################################################
package Conector;
###############################################################
use strict;

# MY MODULES
use Object;
use Server;
use MC_ExpectManager;

@Conector::ISA = ("Object");

sub new {
        my ($prompt) = '(%|#|:|\$|>)'; 
        my ($server,$config) = @_;
        my ($expadm) = new MC_ExpectManager;

        my ($self) = {
                "filename" => undef  ,
                "command"  => undef  ,
                "logsufix" => undef  ,
                "usedpass" => undef   ,
                "server"   => $server ,
                "expadm"   => $expadm ,
        };

        bless $self, 'Conector';   # Tag object with pkg name
        $self->loadConfig($config);
        if ( $self->validateParameters() == 1 ) { return undef $self; }
        return $self;
}
### DESTROY
sub DESTROY {
        my ($self) = shift;
        my ($PKG)  = ref($self);
        $self->{"expadm"}->DESTROY();
        $self->{"server"}->DESTROY();
        return undef $self;
}

sub loadConfig {
        my ($self) = shift;
        my ($config) = @_[0];

        if ( ! $config->{'filename'} eq '' ) {
                $self->{"filename"} = $config->{'filename'};
        }

        if ( ! $config->{'commands'} eq '' ) {
                $self->{"command"}  = $config->{'commands'};
        }

        if ( ! $config->{'log_file_sufix'} eq '' ) {
                $self->{"log_file_sufix"} = $config->{'log_file_sufix'};
        }

}

sub validateParameters {
        my ($self) = shift;
        if ( ! $self->hasFile() and ! $self->hasCommand() ){
                print STDERR "[CONECT] >>>> You must specified a script to run or a list of commands. Nothing to do , Exiting\n"; 
                exit 1;
        }
        if ( ! $self->{"logsufix"} ) { $self->{"logsufix"} = "audit.log"; }
        return 0;
}
# -------------------------------------------------------------------------------------
sub connectServer {
        my ($self) = shift;
        my ($expadm)   = $self->get("expadm");
        my ($server)   = $self->get("server");

        print "[CONECT] >>>> CONNECTING SERVER : ".$server->{"hostname"}."\n";
        $server->print();

        $expadm->startWithConector($self);
        if ( $expadm->evalExpectAutentication() == 0 ){
                #### IF PASSWORD CHANGED WE SET THE SERVER WITH THE NEW ONE
                if ( $self->{'result'} eq "Password Changed" ) {
                        $server->setPasswdWithNewPasswd();
                }
                #### ------------------------------------------------------
                print "[CONECT] >>>> SERVER EXECUTION\n";
                $expadm->remoteExecution();
        } else {
                print STDERR "[CONECT] >>>> SSH EVAL CONNECTION ERROR\n";
        }
        print "[CONECT] >>>> END\n";
        $expadm->end();
}
# -------------------------------------------------------------------------------------
sub hasFile           { my ($self) = shift; return defined $self->{"filename"} ; }
sub hasCommand        { my ($self) = shift; return defined $self->{"command"} ; }
sub logFileName       { my ($self) = shift; my ($server) = $self->get("server"); return $server->{"hostname"}."\_".$self->{"logsufix"}; }
sub fileOnServer      {
        my ($self) = shift;
        if ( $self->hasFile() ) {
                return "/tmp/".$self->{"filename"};
        }
        print STDERR "[CONECT] -ERROR- File On Server not defined !";
        exit 1;
}
sub defaultCommand      { my ($self) = shift; return "hostname; uname -a; date; id; w; uptime > ".$self->logFileOnServer()."\n" }
sub executeFileOnServer { my ($self) = shift; return "perl ".$self->fileOnServer()." > ".$self->logFileOnServer()."\n" }
sub logFileOnServer     { my ($self) = shift; return "/tmp/".$self->logFileName(); }
sub usedPasswdIsUndef   { my ($self) = shift; return not defined $self->get("usedpass"); }

sub runCommandsWithMyExpect {
        my ($self) = shift;
        my ($expadm) = @_[0];
        my ($expect) = $expadm->get("expect");
        my ($to)   = $expadm->get("shorTO");

        if ( $self->hasCommand() ) {
                my (@commands) = split(/;/,$self->get("command"));
                my ($comm);
                print "[CONECT] >>>> COMMAND : @commands\n";
                foreach $comm (@commands) {
                        $expect->send("\n");
                        $expadm->waitingPrompt('#.$');
                        $expect->clear_accum();
                        print "[CONECT] >>>> RUNNING : $comm\n";
                        $expect->send("$comm >> ".$self->logFileOnServer()."\n");
                        ### IF ASK SUDO PASSWD
                        if ( $expect->expect($to,-re,'.*.assword.*:') ) { $expect->send( $self->get("usedpass")."\n"); }
                        $expadm->waitingPrompt('#.$',1800);
                }
        } else {
                ####### IF THERE IS NO COMMAND , WE EXECUTE THE FILE ON THE SERVER
                $expect->send ( $self->executeFileOnServer()."\n" );
        }
        return 1;
}

sub cleanServerWithExpect {
        my ($self) = shift;
        my ($expect) = @_[0];

        if ( $self->hasFile() ) { $expect->send ("rm -f ".$self->logFileOnServer()."; rm -f ".$self->fileOnServer()."\n"); }
        else { $expect->send ("rm -f ".$self->logFileOnServer()."\n"); }
        return 0;
}

sub execute {
        my ($self) = shift;
        $self->connectServer();
        return 0;
}
sub setResult {
        my ($self) = shift;
        my ($result) = @_;
        $self->{"result"} = $result;
        return 0;
}
# ---------------------------------------------------

"1;"

__END__

