#!/usr/bin/perl -s
# -------------------------------------------------------------

###############################################################
package MC_ExpectManager;
###############################################################
use strict;

use Expect;
use Object;
use Conector;
use Server;

@MC_ExpectManager::ISA = ("Object");
sub new {
        my ($prompt) = '(%|#|:|\$|>)'; 
        ### PARA MANIPULAR LAS INSTANCIAS DE EXPECT QUE UTILIZA EL MANEJADOR DE EXPECT
        ### SE IMPLEMENTA UNA PILA(STACK) , EN LA CUAL UTILIZA LA ULTIMA INSTANCIA AGREGADA
        my ($expect) = new Expect;

        my ($self) = {
                "conector" => undef   ,
                "expect"   => $expect , ### UNA REFERENCIA AL ARRAY
                "prompt"   => $prompt ,
                "scp_exp"  => undef   ,
                "longTO"   => "10"    ,
                "shorTO"   => "5"     ,
        };
        bless $self, 'MC_ExpectManager';   # Tag object with pkg name
        $self->loadMC_Config();
        return $self;
}

sub DESTROY {
        my ($self) = shift;
        close(LOG);
        undef $self->{"expect"};
        return undef $self;
}
sub loadMC_Config {
        my ($self) = shift;
        my ($config) = $MegaConector::config ;

        if ( $config->{'long_time_out'} ) {
            $self->{'longTO'} = $config->{'long_time_out'};
        }
        if ( $config->{'short_time_out'} ) {
            $self->{'shorTO'} = $config->{'short_time_out'};
        }

        if ( $config->{'log_dir'} ) {
                $self->{'log_dir'} = $config->{'log_dir'};
        } else {
                $self->{'log_dir'} = "./logs";
        }
}

# ---------------------------------------------------
sub executionLogFileName {
        my ($self) = shift;
        my ($conector) = $self->get("conector");
        my ($server) = $conector->get("server");
        return $server->{"hostname"}."\_exec.log";
}
sub createLogFile {
        my ($self) = shift;
        open (LOG,">".$self->executionLogFileName())
                or die "[MYEXPT] ERROR - no se pudo crear el LOG\n";
}

#######################################################################

sub sshCommand {
        my ($self) = shift;
        my ($server) = @_[0];
        return "ssh ".$server->{"user"}."\@".$server->{"ip"}."\n";
}
sub scpCommand_send {
        my ($self) = shift;
        my ($conector) = $self->{"conector"};
        my ($server) = $conector->get("server");
        return "scp ./".$conector->get("filename")." ".$server->get("user")."\@".$server->get("ip").":/tmp\n";
}
sub scpCommand_get {
        my ($self) = shift;
        my ($conector) = $self->{"conector"};
        my ($server) = $conector->get("server");
        return "scp ".$server->get("user")."\@".$server->get("ip").":".$conector->logFileOnServer()." ".$self->{'log_dir'}."\n";
}
#######################################################################
sub startWithConector {
        my ($self) = shift;
        my ($conector) = @_[0];
        my ($server) = $conector->get("server");
        my ($expect) = $self->{"expect"};

        $self->{"conector"} = $conector;
        #$self->createLogFile();

        $expect->spawn( $self->sshCommand($server) )
                or die "Cannot spawn ".$self->sshCommand($server).": $!\n";
        return 0;
}

sub end {
        my ($self) = shift;
        my ($expect) = $self->{"expect"};

        $expect->clear_accum();
        $expect->soft_close();
        undef $expect;
        undef $self->{"expect"};
        return $self;
}

sub waitingPrompt {
        my ($self) = shift;
        my ($regexp,$to) = @_;
        my ($expect) = $self->{"expect"};

        if ( not defined $regexp ) { $regexp = $self->{"prompt"}; }
        if ( not defined $to     ) { $to = 5; }

        while ( $to != 0 ) {
                # IF IS DEFINED , IS BECAUSE MATCHED A PROMPT OR A REGEXP
                return 0 if defined $expect->expect(1,'-re',$regexp);
                print STDOUT ".";
                $to--;
        }
        print STDOUT "\n";
        print STDOUT "[MYEXPT] << ERROR >> NOTHING MATCHED\n";
        print STDOUT "[MYEXPT] << ERROR >> Waiting for prompt : Nothing matched\n";
        return 1;
}


sub evalSCPExpectAutentication {
        my ($self)     = shift; # expect
        my ($conector) = $self->{"conector"};
        my ($server)   = $conector->get("server");
        my ($expect)   = $self->{"scp_exp"};
        my ($flag)     = 0;
        #### SCP SERVER AUTHENTICATION HANDSHAKING
        $expect->expect( $self->{"longTO"},
                [ qr/.assword:/i, sub {
                        my ($expect) = shift;
                        print "[MYEXPT] - /.assword:/ scp match. passwd requested. \n";
                        $expect->send($conector->get("usedpass")."\n");
                        $flag = 1;
                }],
        );
        if ( $flag ) { return 0; }

        $expect->expect( $self->{"longTO"},
                [ qr/.efused/i, sub {
                        my ($expect) = shift;
                        print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /.efused/ match. Connection refused\n";
                }],[ qr/not.know/i, sub {
                        my ($expect) = shift;
                        print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /not.know/ match. Connection refused.\n";
                }],[ qr/timeout/i, sub {
                        my ($expect) = shift;
                        print STDERR  "[MYEXPT] ERR ".$server->{"hostname"}." - /timeout/ match. Connection timeout.\n";
                }],[ qr/.onnection.closed.by/i, sub {
                        my ($expect) = shift;
                        print STDERR  "[MYEXPT] ERR ".$server->{"hostname"}." - /.onnection.closed.by/ match. Connection closed by remote host.\n";
                }],
        );
        print STDOUT "\n>> There was an error trying to connect...\n";
        return 1;
}



sub evalExpectAutentication {
        my ($self) = shift;
        my ($conector) = $self->{"conector"};
        my ($server) = $conector->get("server");
        my ($expect) = $self->{"expect"};
        my ($result) = undef;
        my ($count) = 0;
        my ($flag) = 1;
        my ($msg) = "";

        #### SERVER AUTHENTICATION HANDSHAKING
        print STDOUT "[MYEXPT] - Connecting server : ".$server->{"hostname"}."\n";

        $expect->expect( $self->{"longTO"},
                [ qr/continue connecting .yes.no./i, sub {
                        my ($expect) = shift;
                        $expect->send("yes\n");
                        $expect->exp_continue; 
                }],[ qr/.assword:/, sub {
                        my ($expect) = shift;
                        $flag = 0;
                        print  "[MYEXPT] - /.assword:/ match passwd requested. \n";
                        $conector->set("usedpass",$server->get("passwd"));
                        $expect->send($conector->get("usedpass")."\n");
                        $conector->setResult("Password OK. Accessing the Matrix");

                        $expect->expect( $self->{"longTO"},
                                [ qr/.ld..assword:/, sub {
                                        my ($expect) = shift;
                                        ###### CHANGIN CURRENT PASSWORD
                                        print "[MYEXPT] - /.ld..assword:/ match. The server requested to type the old password. ";
                                        if ( $server->newpasswdIsDefined() ) {
                                                $expect->send( $server->get("passwd")."\n" );
                                                $conector->setResult("Changing Password");
                                                $expect->exp_continue;
                                        } else {
                                                print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /.ld..assword:/ new password not defined\n";
                                                $conector->setResult("No NewPasswd Defined");
                                                $flag = 1;
                                        }

                                }],[ qr/.ew..assword:/, sub {
                                        my ($expect) = shift;
                                        print "[MYEXPT] - /.ew..assword:/ match. The server requested to type the new password. ";
                                        $conector->set("usedpass",$server->get("newpasswd"));
                                        $expect->send( $server->get("newpasswd")."\n" );
                                        $conector->setResult("Password Changed");
                                        $expect->exp_continue; 

                                }],[ qr/.assword..gain:/, sub {
                                        my ($expect) = shift;
                                        $conector->set("usedpass",$server->get("newpasswd"));
                                        print "[MYEXPT] - /.assword..gain:/ match. The server requested to type the new password. ";
                                        $expect->send( $server->get("newpasswd")."\n" );
                                        $conector->setResult("Password Changed");
                                        $expect->exp_continue;
                                        ##### VALIDATE ERRORS

                                }],[ qr/.assword:/, sub {
                                        if ( $flag eq 0 and not $conector->usedPasswdIsUndef() ) {
                                                $flag = 1;
                                                print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /.assword:/ match.";
                                                print STDERR " Authentication failed. Login attempts [2] - unknow passwd.\n";
                                                $conector->setResult("Wrong passwd");
                                                $expect->send("\cC");
                                        }
                                }]
                        );

                }],[ qr/.efused/, sub {
                        my ($expect) = shift;
                        print STDERR  "[MYEXPT] ERR ".$server->{"hostname"}." - /.efused/ match. Connection refused\n";
                        $conector->setResult("Connection Refused");

                }],[ qr/not.know/, sub {
                        my ($expect) = shift;
                        print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /not.know/ match. Connection refused.\n";
                        $conector->setResult("Not Know Host");

                }],[ timeout => sub {
                        my ($expect) = shift;
                        print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /timeout/ match. Connection timeout.\n";
                        $conector->setResult("Timeout");

                }],[ qr/.onnection.closed.by/, sub {
                        my ($expect) = shift;
                        print STDERR "[MYEXPT] ERR ".$server->{"hostname"}." - /.onnection.closed.by/ match. Connection closed by remote host.\n";
                        $conector->setResult("Connection Closed");

                }]
        );

        ###### WAINTING FOR PROMPT OR CONTINUE
        if ( ! $flag and $self->waitingPrompt() == 0 ) {
                print STDOUT "[MYEXPT] Good! We have a prompt here.\n";
                return 0;
        }

        print STDERR "[MYEXPT] ERROR - The connection could not be established...\n";
        print STDOUT "[MYEXPT] ERROR - The connection could not be established...\n";
        return 1;
}

sub sendFile {
        my ($self)   = shift;
        $self->{"scp_exp"} = new Expect;
        my ($scpexp) = $self->{"scp_exp"};

        print "\n[MYEXPT] >>>> COPYING FILE TO SERVER\n";

        $scpexp->spawn( $self->scpCommand_send() )
                or die "[MYEXPT] ERROR - Cannot spawn ".$self->scpCommand_send().":\n $!\n";
        $self->evalSCPExpectAutentication();
        $scpexp->soft_close();
        undef $self->{"scp_exp"};

        print "\n[MYEXPT] >>>> FILE SENT\n";
        return 0;
}

sub extractFile { 
        my ($self) = shift;
        $self->{"scp_exp"} = new Expect;
        my ($scpexp) = $self->{"scp_exp"};

        print "\n[MYEXPT] >>>> GETTING FILE FROM SERVER\n";

        $scpexp->spawn( $self->scpCommand_get() )
                or die "[MYEXPT] ERROR - Cannot spawn ".$self->scpCommand_get().":\n $!\n";
        $self->evalSCPExpectAutentication();
        $scpexp->soft_close();
        undef $self->{"scp_exp"};

        print "\n[MYEXPT] >>>> FILE OBTAINED\n";
        return 0;
}
# ---------------------------------------------------
sub synchronizeConnection {
        my ($self)     = shift;
        my ($conector) = $self->{"conector"};
        my ($expect)   = $self->{"expect"};
        my ($server)   = $conector->get("server");
        my ($to)       = $self->get("shorTO");


        if ( $expect->expect($to,-re,'TERM') ) { $expect->send("ansi\n"); }
        $self->waitingPrompt();

        print "[MYEXPT] >>>> REMOTE EXECUTION ON ".$server->get("hostname")."\n";
        $expect->send("ksh\n");
        $self->waitingPrompt();

        $expect->send("PS1='".$server->get("hostname")." # '\n");
        $self->waitingPrompt();

        $expect->send("FILE=\"".$conector->logFileOnServer()."\"; if [[ -a \$FILE ]]; then sudo rm \$FILE; fi\n");
        if ( $expect->expect(5,-re,'.*.assword.*:') ) { $expect->send( $conector->get("usedpass")."\n"); }

        $expect->send( "touch ".$conector->logFileOnServer()." && chmod 777 ".$conector->logFileOnServer() );
        return 0;
}

sub remoteExecution {
        my ($self)     = shift;
        my ($conector) = $self->{"conector"};
        my ($expect)   = $self->{"expect"};
        my ($server)   = $conector->get("server");
        my ($to)       = $self->get("shorTO");

        print "\n[MYEXPT] >>>> SYNCHRONIZE CONNECTION\n";
        $self->synchronizeConnection();
        $self->waitingPrompt();

        if ( $conector->hasFile() ) {
                ###### UPLOAD THE FILE TO THE SERVER
                $self->sendFile();
                $expect->send("\n");
        }

        $self->waitingPrompt('#.$');
        $expect->clear_accum();

        print "\n[MYEXPT] >>>> RUNNING COMMANDS\n";
        $conector->runCommandsWithMyExpect($self);
        $expect->send("\n");
        sleep(2);

        ####### GET BACK EXECUTION EVIDENCE
        $self->waitingPrompt('#.$');
        print "\n[MYEXPT] >>>> GATHERING EXECUTION LOG FILE\n";
        $self->extractFile();
        $expect->send("\n");

        ####### DELETE EVIDENCE
        $self->waitingPrompt;
        print "\n[MYEXPT] >>>> CLEANNING SERVER\n";
        $conector->cleanServerWithExpect($expect);

        ####### CLOSE CONECTIONS
        $self->waitingPrompt('#.$');
        print "\n[MYEXPT] >>>> CLOSING CONECTION WITH ".$server->get("hostname")."\n";
        print "\n[MYEXPT] >>>> CLOSING KSH SESION\n";
        $expect->send("\nexit\n");
        ####### EL SEGUNDO
        print "\n[MYEXPT] >>>> EXITING ".$server->get("hostname")."\n";
        $expect->send("\nexit\n");

        return 0;
}

"1;"
__END__
