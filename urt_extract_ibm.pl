#!/usr/bin/perl
#=========================================================================
# (C) Copyright 2006 IBM Corporation
#=========================================================================
# Script Name    : urt_extract.pl
# Script Purpose : extract urt data
# Parameters     : $1 URT customer name (optional)
#                  $2 password file (optional)
#                  $3 group file (optional)
#                  $4 Output file name (optional)
#                  $5 Hostname (optional)
# Output         : file in URT .mef format
# Dependencies   : Perl
#-------------------------------------------------------------------------------
# Version Date         # Author              Description
#-------------------------------------------------------------------------------
# V3.0.0  2006-04-28   # Matthew Waterfield  Ported from ksh and to .mef v2
# V3.1.0  2006-06-22   # Matthew Waterfield  Fix open issue on old perls
# V4.0.0  2006-10-18   # Matthew Waterfield  Enhance to get state
# V4.1.0  2006-10-25   # Matthew Waterfield  Add output file checks
# V4.2.0  2006-11-06   # Matthew Waterfield  Change to GetOptions and tidy
# V4.2.1  2006-11-06   # Matthew Waterfield  Check priv groups against URT list
# V5.0.0  2007-05-23   # iwong  Added parsing of gecos for IBM SSSSSS CCC, added 3-digit CC to 2-digit
#  				Added parsing of sudoers, and sudoer group processing
#  				Added --sudoers flag
#  				update ouput to include:
#				  usergecos = CC/I/SSSSSS//gecos - process gecos and pulls Serial and Country Code
#				  usergroup =  list of groups which give this ID SUDO priviledges
#				  userprivgroup = SUDO if found in sudoerReport, else blank
# V5.1.0  2007-07-18   # iwong  Updated code to default status=C, serial="", and  cc=US, if not IBM
#			        Setup default customer, and added new customer flag
#     			        Updated code adding hostname to default mef file name
# V5.1.1  2007-08-02   # iwong  Updated code to read URT format CCC/I/SSSSSS//gecos
# V5.1.2  2007-08-28   # iwong  Updated code to fix problem with -meffile flag
# V5.1.3  2007-09-13   # iwong  Updated code to warn if no sudoers files found
# V5.2.0  2007-09-26   # iwong  Updated code to generated scm formated output file
# V5.2.2  2007-11-07   # iwong  Updated code read in cust and comment fomr URT format CCC/I/SSSSSS/cust/comment
#                      #        Updated default user status state to enabled(0), if state unknown
# V5.2.3  2007-11-28   # iwong  Updated warning messages to indicated which files are missing
#		       #        Updated code to indicate if SUDO priv is granted by a group(SUDO-GRP) or user(SUDO-USR)
#		       #        Moved OS default file stanza to after arg assignments
# V5.2.4  2007-11-29   # iwong  Updated code output .scm9 format, which includes auditDATE
#                      #        Fixed problem accounts disabled with account_locked in SECUSER
# V5.2.5  2007-12-05   # iwong  Updated code to check for HP-UX systems(TCB and non-TCB)
# V5.2.6  2007-12-11   # leduc  If comments contain IBM flag = I
# V5.2.7  2008-01-25   # iwong  Updated code changing SUDO-USR to SUDO and SUDO-GRP to list of sudo groups
# V5.2.8  2008-02-21   # iwong  Updated code output .mef format
# V5.2.9  2008-02-21   # iwong  getprpw command to properly report HP disabled users
# V5.2.10 2008-02-21   # iwong  Bypass disabled check for * in passwd field in passwd file on hpux TCB systems
#			        Updated output file name, if customer different from default IBM
#			        added debug flag
# V5.2.11 2008-02-21   # iwong  Created new parsespw_hpux subroutine to check getprpw or shadow file
# V6.0    2008-04-11   # iwong  Added -scm flag, to output scm9 format, changed meffile flag to outfile
#			        Output OS type in scm formated files
#			        Recognize OSR privileged user and groups per OS type
#			        Updated groups and privileges fields include OSR ans SUDO privs
#			        Add script integrity cksum check
#			        Uniquify group and SUDO group lists
#			        Remove 3-digit CC conversion
#			        Added -privfile flag to read in additional priv groups from a file
#			        Updated code output .mef3 format
# V6.1    2008-04-18   # iwong  Updated code group field output to list all groups a user is a member
#			        Commented out cksum check 
# V6.2    2008-04-23   # iwong  Fixed problem with primary groups, not shown for ids not in any groups
#			        Add wheel to Linux default priv group list
#			        Fixed problem with reading in additional priv group 
# V6.3    2008-04-30   # iwong  Added code to skip Defaults in sudoers file
#		  	        Added code to fix problem with lines with spaces/tabs after \ in sudoers file
#		  	        Added additional debug statement for sudoers processing
#		  	        Added additional processing of ALL keyword in sudoers
# V6.4    2008-05-13   # iwong  Commented out cksum code 
# V6.5    2008-05-15   # iwong  Added -mef flag, to output mef2 format
# V6.6    2008-06-03   # iwong  Added code to process groups in the User_Alias
# V6.7    2008-06-11   # iwong  Added code ignore netgroup ids +@user, any id starting with +
# V6.8    2008-06-17   # iwong  Added code adding dummy record to end of output file with date and versioning information
# V6.9    2008-07-28   # iwong  Updated dummy record to include 000 cc
#===============================================================================

# Modules
use File::Basename;
use Getopt::Long;
use Cwd qw(abs_path);

# Version
$VERSION='V6.9  2008-07-28';

# Set up some constants
%CC = (
'559', 'TT',
'603', 'AL',
'612', 'DZ',
'613', 'AR',
'615', 'BD',
'616', 'AU',
'618', 'AT',
'619', 'BS',
'620', 'BH',
'621', 'BB',
'624', 'BE',
'627', 'BM',
'629', 'BO',
'631', 'BR',
'636', 'BW',
'644', 'BG',
'649', 'CA',
'650', 'CM',
'652', 'LK',
'655', 'CL',
'656', 'GA',
'661', 'CO',
'663', 'CR',
'659', 'CR',
'666', 'CY',
'668', 'CZ',
'672', 'CN',
'677', 'AE',
'678', 'DK',
'681', 'DO',
'683', 'EC',
'693', 'SK',
'694', 'KZ',
'699', 'BA',
'702', 'FI',
'704', 'HR',
'705', '00',
'706', 'FR',
'707', 'YU',
'708', 'SL',
'724', 'DE',
'726', 'GR',
'731', 'GT',
'735', 'HN',
'738', 'HK',
'740', 'HU',
'744', 'IN',
'IN1', 'IN',
'749', 'ID',
'754', 'IE',
'756', 'IL',
'757', 'CI',
'758', 'IT',
'759', 'JM',
'760', 'JP',
'JP3', 'JP',
'762', 'JO',
'766', 'KR',
'767', 'KW',
'768', 'LB',
'778', 'MY',
'781', 'MX',
'784', 'MA',
'788', 'NL',
'791', 'AN',
'796', 'NZ',
'798', 'LA',
'799', 'NI',
'805', 'OM',
'806', 'NO',
'808', 'PK',
'811', 'PA',
'813', 'PY',
'815', 'PE',
'818', 'PH',
'820', 'PL',
'821', 'RU',
'822', 'PT',
'823', 'QA',
'824', 'SN',
'825', 'ZW',
'826', 'RO',
'829', 'SV',
'832', 'SA',
'834', 'SG',
'838', 'ES',
'840', 'TN',
'843', 'SR',
'846', 'SE',
'848', 'CH',
'852', 'VN',
'856', 'TH',
'858', 'TW',
'862', 'TR',
'864', 'ZA',
'865', 'EG',
'866', 'GB',
'869', 'UY',
'871', 'VE',
'877', 'FX',
'889', 'UA',
'897', 'US',
'CA2', 'CP',
'CA3', 'CP',
'CA4', 'CP',
'CA6', 'CP',
'CA7', 'CP',
'US5', 'US',
);


$ErrCnt=0;

chomp($SNAME=`basename $0`);
( $USAGE = <<USAGE_TEXT );
Usage: $SNAME <--help>
USAGE_TEXT

# Usage help
( $OPTHELP = <<OPT_HELP );
Options Help: 
  Optional overrides:
	--customer <customer name> 
	--passwd   <passwd_file> 
	--shadow   <shadow_passwd_file> 
	--group    <group_file>
	--secuser  <aix_security_user_file>
	--hostname <hostname>
	--os       <operating_system_name>
	--outfile  <output_file>
	--sudoers  <sudoers_file>
	--scm
	--mef
	--privfile  <additional _priv_group_file>

   Options Notes:
	--passwd, --shadow, --group, --secuser, --sudoers
	  Use these options for running the extract
	  against files copied from one system 
	  to another.
	  You might do this if perl is not available
	  on the target system. Or for testing.
	
	--customer
	  Specify the customer name 

	--hostname
	  Specify the hostname to appear in the outfile.
	  This is useful when system is known
	  by a name different to the system hostname.
	  Or when extract is run on a different
	  system e.g. when files have been copied.
	
	--os
	  Use when extract is run on a system with 
	  a different operating system to the input
	  files.(aix|hpux|sunos|linux|tru64) 
	  e.g. --os aix
	
	--outfile
	  The default outfile is /tmp/<urt_customer_name>_<date>_<hostname>.mef3
	  You can change the path/name if required.

	--scm
	  Change output file format to scm9, instead of mef3

	--mef
	  Change output file format to mef2, instead of mef3

	--privfile
	  Additional Privilege Group file(One group per line in file)

   General Notes:
	. Output is mef3 or scm9 or mef2 format including privilege data.
	. Only reports on local userids - ie no LDAP etc.
	. List of privileged groups is hardcoded in the script 
	  (easy to change if required by person running the script)
	. User 'state' (enabled/disabled) is extracted if possible.
	. User 'l_logon' (last login date) is not extracted.
	. Only tested on perl v5.  
OPT_HELP

#===============================================================================
# Main process flow
#===============================================================================
&init();
&parsegp();
&parsepw();
&parsesudoers();
if ($OS =~ /aix/i)
   {
   if($DEBUG){
      print "DEBUG: running as aix\n"; #debug
      }
   &parsespw_aix();
   }
elsif ($OS =~ /hpux/i)
   {
   if($DEBUG){
      print "DEBUG: running as hpux\n"; #debug
      }
   &parsespw_hpux();
   }
else
   {
   &parsespw($OS);
   }
&openout();
&report();

#===============================================================================
# Subs
#===============================================================================
sub init()
{
	# Print Version
	print "$SNAME#  $VERSION\n";

	## get cksum on script
	open(CKFILE, $0)||die"ERROR: failed to open $0:$?\n";
	$special= $/;
	undef $/;
	$CKSUM=unpack("%32C*",<CKFILE>) % 32767;
	#print "      CKSUM: $CKSUM\n";
	#print "    special: $special\n";
	close CKFILE;
	$/ = $special;



	# System details
	chomp($HOST=`uname -n`);
	chomp($DATE=`date +%d%b%Y`);
	$DATE=uc($DATE);
	$OS=$^O;	# short operating system name
	$DEBUG=0;
	$SCMFORMAT=0;
	$MEF2FORMAT=0;

	#auditdate is the date of the last scm collector run corresponding to this 
	#hostname in the format yyyy-mm-dd-hh.mm.ss (2006-04-02-00.00.00)..
        #yyyy-mm-dd-hh.mm.ss
	chomp($myAUDITDATE=`date +%Y-%m-%d-%H.%M.%S`);


	# Default file locations which dont depend on OS
	$URTCUST="IBM";
	$PASSWD="/etc/passwd";
	$GROUP="/etc/group";
	$SUDOERS="/etc/sudoers";
        $OUTFILE = "/tmp/$URTCUST\_$DATE\_$HOST.mef3";
        $NEWOUTFILE = "";
        $PRIVFILE = "";

	# Now use getopts to process rest in a more manageable way
	$OK = GetOptions("help"	=> \&help,
		   "customer=s"	=> \$URTCUST,
		   "passwd=s" 	=> \$PASSWD,
		   "shadow=s" 	=> \$SPASSWD,
		   "group=s" 	=> \$GROUP,
		   "sudoers=s" 	=> \$SUDOERS,
		   "secuser=s" 	=> \$SUSER,
		   "hostname=s"	=> \$HOST,
		   "os=s"	=> \$OS,
		   "debug"	=> \$DEBUG,
		   "scm"	=> \$SCMFORMAT,
		   "mef"	=> \$MEF2FORMAT,
		   "privfile:s" => \$PRIVFILE,
		   "outfile:s" 	=> \$NEWOUTFILE);

	# File locations which depend on OS
	for ($OS) 
	  {
	  if($DEBUG){ print "OS: $OS\n"; }
	  if (/aix/i)
	    {
	    if($DEBUG){ print "DEBUG: Found AIX\n"; }
	    $SPASSWD = $SPASSWD ? $SPASSWD : "/etc/security/passwd";
	    $SUSER = $SUSER ? $SUSER : "/etc/security/user";
	    # Define priv groups - this is an extended regex ie pipe separated list of things to match
            $PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^nuucp$|^lpd$|^imnadm$|^ipsec$|^ldap$|^lp$|^snapp$|^invscout$|^nobody$|^notes$';
	    $PRIVGROUPS='^system$|^security$|^bin$|^sys$|^adm$|^uucp$|^mail$|^printq$|^cron$|^audit$|^shutdown$|^ecs$|^imnadm$|^ipsec$|^ldap$|^lp$|^haemrm$|^snapp$|^hacmp$|^notes$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$';
	    }
	  elsif (/hpux/i)
	    {
	    if($DEBUG){ print "DEBUG: Found HPUX\n"; }
	    $SPASSWD = $SPASSWD ? $SPASSWD : "/etc/shadow";
	    $PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^lp$|^nuucp$|^hpdb$|^imnadm$|^nobody$|^notes$';
	    $PRIVGROUPS='^root$|^other$|^bin$|^sys$|^adm$|^daemon$|^mail$|^lp$|^tty$|^nuucp$|^nogroup$|^imnadm$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$|^notes$';
	    }
	  elsif (/sunos/i || /solaris/i)
	    {
	    if($DEBUG){ print "DEBUG: Found SUN\n"; }
	    $SPASSWD = $SPASSWD ? $SPASSWD : "/etc/shadow";
	    $PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^nuucp$|^imnadm$|^lp$|^smmsp$|^listen$';
	    $PRIVGROUPS='^system$|^security$|^bin$|^sys$|^uucp$|^mail$|^imnadm$|^lp$|^root$|^other$|^adm$|^tty$|^nuucp$|^daemon$|^sysadmin$|^smmsp$|^nobody$|^notes$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$';
	    }
	  elsif (/linux/i)
	    {
	    if($DEBUG){ print "DEBUG: Found LINUX\n"; }
	    $SPASSWD = $SPASSWD ? $SPASSWD : "/etc/shadow";
	    $PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^nobody$|^notes$';
	    $PRIVGROUPS='^notes$|^mqm$|^dba$|^sapsys$|^db2iadm1$|^db2admin$|^sudo$|^wheel$';
	    }
	  elsif (/tru64/i)
	    {
	    if($DEBUG){ print "DEBUG: Found TRU64\n"; }
	    $SPASSWD = $SPASSWD ? $SPASSWD : "/etc/shadow";
	    $PRIVUSERS='^adm$|^auth$|^bin$|^cron$|^daemon$|^inmadm$|^lp$|^nuucp$|^ris$|^root$|^sys$|^tcb$|^uucp$|^uucpa$|^wnn$';
	    $PRIVGROUPS='^adm$|^auth$|^backup$|^bin$|^cron$|^daemon$|^inmadm$|^kmem$|^lp$|^lpr$|^mail$|^mem$|^news$|^operator$|^opr$|^ris$|^sec$|^sysadmin$|^system$|^tape$|^tcb$|^terminal$|^tty$|^users$|^uucp$';
	    }
	  else
	    {
	    if($DEBUG){ print "DEBUG: Found Unknown\n"; }
            $PRIVUSERS='^root$|^daemon$|^bin$|^sys$|^adm$|^uucp$|^nuucp$|^lpd$|^imnadm$|^ipsec$|^ldap$|^lp$|^snapp$|^invscout$|^nobody$|^notes$';
	    $PRIVGROUPS='^1bmadmin$|^adm$|^audit$|^bin$|^cron$|^daemon$|^db2admin$|^db2iadm1$|^dba$|^ecs$|^hacmp$|^haemrm$|^ibmadmin$|^imnadm$|^ipsec$|^ldap$|^lp$|^mail$|^mqm$|^nobody$|^nogroup$|^notes$|^nuucp$|^other$|^printq$|^root$|^sapsys$|^security$|^shutdown$|^smmsp$|^snapp$|^suroot$|^sys$|^sysadm$|^system$|^tty$|^uucp$|^wheel$';
	    $SPASSWD = $SPASSWD ? $SPASSWD : "/etc/shadow";
	    }
	  } # end for
	if($DEBUG){ 
	    print "PRIVUSERS: $PRIVUSERS\n"; 
	    print "PRIVGROUPS: $PRIVGROUPS\n"; 
	    }

        if($PRIVFILE ne "")
	  {
   	  if($DEBUG){ 
	    print "Reading PRIVFILE: $PRIVFILE\n"; 
	    }
	  open(PRIVFILE, $PRIVFILE) || die "ERROR: Can't open PRIVFILE: $PRIVFILE : $!\n";
	  while($line=<PRIVFILE>)
	    {
	    chomp $line;
	    $readgroup="";
	    ($readgroup)=$line=~/^\s*(\S+)\s*$/;
	    if($readgroup ne "")
              {$PRIVGROUPS.="|^".$readgroup."\$";
   	      if($DEBUG){ print "Adding privgroup: $readgroup\n"; }
	      }
	    else
	      {
   	      if($DEBUG){ print "Skipping privgroup: $line\n"; }
	      }
	    }
	  if($DEBUG){ 
	    print "Additional PRIVGROUPS: $PRIVGROUPS\n"; 
	    }

	  }
	if ( $OK != 1 )
	{
		print STDERR "ERROR: Problem processing options\n";
		print "\n$USAGE\n";
		exit 1;
	}

	## check to see if given a specfic outfile name
	if ($NEWOUTFILE eq "")
	  {
	  # update default outfile if scm
	  if ($SCMFORMAT)
	    {$OUTFILE = "/tmp/$URTCUST\_$DATE\_$HOST.scm9";}
	  elsif ($MEF2FORMAT)
	    {$OUTFILE = "/tmp/$URTCUST\_$DATE\_$HOST.mef";}
	  else
	     {$OUTFILE = "/tmp/$URTCUST\_$DATE\_$HOST.mef3";}
          }
       else
	  {$OUTFILE = $NEWOUTFILE;}


	#debug
	#print "DEBUG: getoptsok <$OK>\n";	#debug
	print "    URTCUST: $URTCUST\n";	#debug
	print " PASSWDFILE: $PASSWD\n";	#debug
	print " SHADOWFILE: $SPASSWD\n";	#debug
	print "  GROUPFILE: $GROUP\n";	#debug
	print "SUDOERSFILE: $SUDOERS\n";	#debug
	print "SECUSERFILE: $SUSER\n";	#debug
	print "         OS: $OS\n";	#debug
	print "    OUTFILE: $OUTFILE\n";	#debug
	print "  SCMFORMAT: $SCMFORMAT\n";	#debug
	print " MEF2FORMAT: $MEF2FORMAT\n";	#debug
	print "      CKSUM: $CKSUM\n";




        print "\nResults are written to $OUTFILE\n";

        print "--------------------------------------------------------------\n\n";

	# If we have any args left we will let the user know and abort
	foreach (@ARGV) {
		print STDERR "ERROR: Incorrect arguments\n";
		print "\n$USAGE\n";
		exit 1;
	}


} # end init sub

sub help()
{
	# print help if requested
	print "\n$USAGE\n";
	print "$OPTHELP\n";
	print "Defaults:\n";
	print "    URTCUST: $URTCUST\n";	#debug
	print " PASSWDFILE: $PASSWD\n";	#debug
	print " SHADOWFILE: $SPASSWD\n";	#debug
	print "  GROUPFILE: $GROUP\n";	#debug
	print "SUDOERSFILE: $SUDOERS\n";	#debug
	print "SECUSERFILE: $SUSER\n";	#debug
	print "         OS: $OS\n";	#debug
	print "    OUTFILE: $OUTFILE\n";	#debug
	print "      CKSUM: $CKSUM\n";
	exit 0;
}

sub parsepw()
{
	# check to see if this is a TCB HPUX system
	# if getprpw is found, we assume this is a TCB machine
	$HPUX_TCB_READABLE=0;
        if($OS =~ /hpux/i)
	    {
	    # check to see if command is executable
	    if(-x "/usr/lbin/getprpw")
	       {
	       $HPUX_TCB_READABLE=1;
	       }
	    }
	if($DEBUG){
	  print "DEBUG: HPUX_TCB_READABLE: $HPUX_TCB_READABLE\n"; #debug
	  }
	open(PASSWD_FILE, $PASSWD) || die "ERROR: Can't open $PASSWD : $!\n";
	while (<PASSWD_FILE>)
	{
		# parse passwd file
		($username, $passwd, $uid, $gid, $gecos, $home, $shell) = split(/:/);
		# store bits of user details in hashes
			# comment any we dont need to save memory !
			#$user_passwd{$username} = $passwd;
			#$user_uid{$username} = $uid;
		# only save priv groups
		if ($username =~ /$PRIVUSERS/)
		  {
		  $user_privuser{$username} = $username;
		  } # end if
		$user_gid{$username} = $gid;
		$user_gecos{$username} = $gecos;
		chomp $shell;
		
		# check for user disabled by * in password field
		# Bypass if this is an TCB HPUX system
		if ($HPUX_TCB_READABLE == 0)
		{
		  if ( $passwd =~ /^\*/ )
		  {
			$user_state{$username} = "Disabled";
			$scm_user_state{$username} = "1";
			if($DEBUG){
			print "DEBUG: $username Disabled: passwd=$passwd in passwd file\n"; #debug
			}
		  }
		}
		else
		{
			if($DEBUG){
			print "DEBUG: $username Bypassing check for user disabled by * in password field\n"; #debug
			}
		}
		if ( $shell =~ /\/bin\/false/ )
		{
			$user_state{$username} = "Disabled";
			$scm_user_state{$username} = "1";
			if($DEBUG){
			print "DEBUG: $username Disabled: shell=$shell in passwd file\n"; #debug
			}
		}
		if ( $shell =~ /\/usr\/bin\/false/ )
		{
			$user_state{$username} = "Disabled";
			$scm_user_state{$username} = "1";
			if($DEBUG){
			print "DEBUG: $username Disabled: shell=$shell in passwd file\n"; #debug
			}
		}

  		## add users to group memberlist  array if user is no listed in its primary group 
  		%gmemlist="";
  		if ( $gmembers{$gid} eq "" ) {
    		  $gmembers{$gid} = $username;
    		  }
  		else {
    		  # add user only user not in current list
    		  foreach $nlist (split(/\,/,$gmembers{$gid}))
      			{ $gmemlist{$nlist}=$nlist; }
    	  	  if($gmemlist{$username}) 
      			{
			## already in list
      			}
    		  else
      			{$gmembers{$gid} = $gmembers{$gid}.",$username"; 
			if($DEBUG){
			   print "DEBUG: Adding $username to gid:$gid user list $gmembers{$gid} \n"; #debug
			  }
			}
    		  }

	} # end while
	
	close PASSWD_FILE;
} # end sub parse

sub parsespw()
{
	$lOS=$_[0];
	open(SPASSWD_FILE, $SPASSWD) || warn "WARN:  Can't open SPASSWD:$SPASSWD : $!\nWARN:  Account state may be missing from extract\n";
	while (<SPASSWD_FILE>)
	{
		# set flag so we know what we've done
		$done_spasswd = 1;
		# parse shadow passwd file
		($username, $crypt_passwd, @rest) = split(/:/);

		# check for user disabled by NP, *LK*, !!, or * in password field
	        if ( $crypt_passwd eq "NP" or $crypt_passwd eq "\*LK\*" or $crypt_passwd eq "!!" or $crypt_passwd =~ /^\*/)
		   {
		   $user_state{$username} = "Disabled";
		   $scm_user_state{$username} = "1";
		   if($DEBUG){
		     print "DEBUG: $username Disabled: crypt=$crypt_passwd in shadow\n"; #debug
		     }
		   }
	        if ( $crypt_passwd eq "LOCKED")
		   {
		   $user_state{$username} = "Disabled";
		   $scm_user_state{$username} = "1";
		   if($DEBUG){
		     print "DEBUG: $username Disabled: crypt=$crypt_passwd in shadow\n"; #debug
		     }
		   }

	} # end while
	
	close SPASSWD_FILE;

	# if we have processed the file set state_available flag
	if ( $done_spasswd == 1 ) 
	{
		$state_available = 1;
	}

} # end sub parse

sub parsespw_hpux()
{
	# check to see if command is executable
	# if getprpw is found, we assume this is a TCB machine
	if(-x "/usr/lbin/getprpw")
	    {
	    open(PASSWD_FILE, $PASSWD) || die "ERROR: Can't open $PASSWD : $!\n";
	    while (<PASSWD_FILE>)
	       {
		# set flag so we know what we've done
		$done_getprpw = 1;
		# parse passwd file
		($username, $crypt_passwd, @rest) = split(/:/);

	        $getprpwdcmd="/usr/lbin/getprpw -m lockout $username|";
		#$getprpwdcmd="echo \"lockout=0010000\"|";
		open(GETPRPW, $getprpwdcmd) || warn "WARN:  Can't open $getprpwdcmd : $!\nWARN:  Account state may be missing from extract\n"; 
		$hpstatus=<GETPRPW>;chomp $hpstatus;
		# set flag so we know what we've done
		if($hpstatus =~ /1/)
		     {
			$user_state{$username} = "Disabled";
			$scm_user_state{$username} = "1";
			if($DEBUG){
			   print"DEBUG: parsespw_hpux: $username Disabled hpstatus=$hpstatus returned from getprpw\n"; 
			   }
		     }
	        else
		     {
			if($DEBUG){
			   print"DEBUG: parsespw_hpux: $username  hpstatus=$hpstatus\n"; 
			   }
		     }

	       close GETPRPW;
	       } # end while
	    close PASSWD_FILE;
	    }
	else
	    {
	    warn "WARN:  Can't access /usr/lbin/getprpw\nWARN:  Account state may be missing from extract\n"; 
	    }

        ## Check shadow file if it exists and have access
	open(SPASSWD_FILE, $SPASSWD) || warn "WARN:  Can't open SPASSWD:$SPASSWD : $!\nWARN:  Account state may be missing from extract\n";
	while (<SPASSWD_FILE>)
	{
		# set flag so we know what we've done
		$done_spasswd = 1;
		# parse shadow passwd file
		($username, $crypt_passwd, @rest) = split(/:/);

		# check for user disabled by NP, *LK*, !!, or * in password field
	        if ( $crypt_passwd eq "NP" or $crypt_passwd eq "\*LK\*" or $crypt_passwd eq "!!" or $crypt_passwd =~ /^\*/)
		   {
		   $user_state{$username} = "Disabled";
		   $scm_user_state{$username} = "1";
		   if($DEBUG){
		     print "DEBUG: $username Disabled: crypt=$crypt_passwd in shadow\n"; #debug
		     }
		   }
	        if ( $crypt_passwd eq "LOCKED")
		   {
		   $user_state{$username} = "Disabled";
		   $scm_user_state{$username} = "1";
		   if($DEBUG){
		     print "DEBUG: $username Disabled: crypt=$crypt_passwd in shadow\n"; #debug
		     }
		   }

	} # end while
	
	close SPASSWD_FILE;

	# if we have processed the file set state_available flag
	if ( $done_spasswd == 1 or $done_getprpw == 1 ) 
	{
		$state_available = 1;
	}

} # end sub parse


sub parsespw_aix()
{
	# Do security/passwd file
	open(SPASSWD_FILE, $SPASSWD) || warn "WARN:  Can't open SPASSWD:$SPASSWD : $!\nWARN:  Account state may be missing from extract\n";
	while (<SPASSWD_FILE>)
	{
		# set flag so we know what we've done
		$done_spasswd = 1;
		# parse security passwd file
		# Find the usernane
		if (/(.+):/)
		{
			# $1 is the bit matched by (.+)
			$username = $1;
			next;
		}
		# Find the password
		if (/password = (.+)/)
		{
			# $1 is the bit matched by (.+)
			# check for user disabled by * in password field
			$crypt_passwd = $1;
			if ($crypt_passwd =~ /^\*/ )
			{
			        $user_state{$username} = "Disabled";
				$scm_user_state{$username} = "1";
				if($DEBUG){
				 print "DEBUG: $username Disabled: password=$crypt_passwd in security passwd\n"; #debug
				 }
			}
			next;
		}

	} # end while
	
	close SPASSWD_FILE;

	# Now do user security/user file
	open(SUSER_FILE, $SUSER) || warn "WARN:  Can't open SECUSER:$SUSER : $!\nWARN:  Account state may be missing from extract\n";
	while (<SUSER_FILE>)
	{
		# set flag so we know what we've done
		$done_suser = 1;
		# parse security user file
		# Find the usernamne
		if (/(.+):/)
		{
			# $1 is the bit matched by (.+)
			$username = $1;
			next;
		}
		# Find the password
		if (/account_locked = (.+)/)
		{
			# $1 is the bit matched by (.+)
			# check for user disabled by true in account_locked field
			$account_locked = $1;
			#print "DEBUG: $username account_locked: $account_locked in security user\n"; #debug
			if ($account_locked =~ /true/i )
			{
			        $user_state{$username} = "Disabled";
				$scm_user_state{$username} = "1";
				if($DEBUG){
				 print "DEBUG: $username Disabled: account_locked=$account_locked in security user\n"; #debug
				 }
			}
			next;
		}

	} # end while
	
	close SUSER_FILE;

	# if we have processed both files set state_available flag
	if ( $done_spasswd == 1 and $done_suser == 1 ) 
	{
		$state_available = 1;
	}
	#print "DEBUG: <$done_spasswd:$done_suser:$state_available>\n"; #debug

} # end sub parse

sub parsegp()
{
	open(GROUP_FILE, $GROUP) || die "ERROR: Can't open $GROUP : $!\n";
	while (<GROUP_FILE>)
	{
		# parse group file
		($groupname, $passwd, $gid, $userlist) = split(/:/);
                chomp $userlist;


		# store group-gid info in hash
		$group{$gid} = $groupname;
		$ggid{$groupname} = $gid;
  		$gmembers{$gid} = $userlist;
                #print "SUB parsegp(): read in $groupname($gid) = $gmembers{$gid}\n";

		# store priv user groups info in hash
		foreach $username (split(/,/,$userlist))
		{
			if (exists $user_allgroups{$username})
			  {
			  $user_allgroups{$username} = $user_allgroups{$username} . "," . $groupname;
			  }
			else
			  {
			  $user_allgroups{$username} = $groupname;
			  } # end if
			#print "ADDING $groupname to $username list: $user_allgroups{$username} \n";
			# only save priv groups
			if ($groupname =~ /$PRIVGROUPS/)
			{
				if (exists $user_privgroups{$username})
				{
					$user_privgroups{$username} = $user_privgroups{$username} . "," . $groupname;
				}
				else
				{
					$user_privgroups{$username} = $groupname;
				} # end if
			} # end if

		} # end foreach

	} # end while
	
	close GROUP_FILE;
} # end sub parse


sub parsesudoers()
{
	$SUDOALL="0";
        open(SUDOERS_FILE, $SUDOERS) || warn "WARN:  Can't open SUDOERS:$SUDOERS : $!\nWARN:  Account SUDO privileges will be missing from extract\n";
        while ($nextline = <SUDOERS_FILE>)
          {
	  if($DEBUG){
	    print "SUDOERS:--> $nextline";
	    }
      	  chomp $nextline;
          ## concatenate line with next line if line ends with \
    	  if ( $nextline =~ /\\\s*$/ ) {
      		# process continuation line
      		($nline)=$nextline=~/(.*)\\\s*$/;
      		chomp($nline);
      		chop($nextline);
      		$InputLine .= $nline;
      		next;
      		}
    	  $InputLine .= $nextline;
	  #print "InputLine: $InputLine\n";

	  ## trim out comment lines
      	  $cmt_ix = index( $InputLine, "#" );
 	  if ( $cmt_ix >= 0 ) {
    		$InputLine = substr( $InputLine, 0, $cmt_ix);
    		}

  	  # split line into tokens (names and keywords)
	  @Line = split /[,=\s]/, $InputLine;
  	  $ix = 0;

  	  # classify pieces of the input
  	  TOKEN: while ( $ix <= $#Line ) {
    	  if ( $Line[$ix] eq "" ) {  # ignore seperators
      		$ix++;
      		next TOKEN;
      		}
    	  if ( $Line[$ix] eq "Cmnd_Alias" ){
      		last TOKEN;
      		}
    	  if ( $Line[$ix] eq "Host_Alias" ){
      		last TOKEN;
      		}
      	  if ( $Line[$ix] eq "Runas_Alias" ){
      		last TOKEN;
      		}
      	  if ( $Line[$ix] eq "Defaults" ){
      		last TOKEN;
      		}
      	  if ( $Line[$ix] eq "ALL" ){
	        $SUDOALL="1";
      		last TOKEN;
      		}
    	  if ( $Line[$ix] eq "User_Alias" ){  # extract user names
      		# User_Alias USERALIAS = user-list
      		$ix++;
      		UALIAS: while ( $ix <= $#Line ) {  # skip white space
        		if ( $Line[$ix] ne "" ) {
          			last UALIAS;
          			}
        		$ix++;
        		}  # end UALIAS while

      		# record useralias name so that it is not confused with a user name
		if($DEBUG){
		  print "SUDOERS: $InputLine\n";
		  print "SUDOERS: Found user_alias $Line[$ix]\n";
		  }
      		$AliasList{ $Line[$ix] }++;

     		#
      		# add remainder of line as user names
      		$ix++;
      		while ( $ix <= $#Line ) {

      		# processing groups listed in User Alias
		        if( $Line[$ix] =~ s/^%//) {
			   if ($ggid{$Line[$ix]} eq "") {
			      printf STDOUT "ERROR: invalid group %s in $SUDOERS User_Alias\n", $Line[$ix];
			      $ErrCnt++;
			      return 1;
			      }
			   my $Members;
			   my $NewName;
			   if($DEBUG){
			      print "SUDOERS: Found group $Line[$ix] in User_Alias\n";
			      }
			   # Swapped out function calls with access of the prepopulated associative arrays
			   $Members = $gmembers{$ggid{$Line[$ix]}};
			   foreach $NewName (split ',', $Members) {
			      if($DEBUG){
				 print "SUDOERS: Found user $NewName in group $Line[$ix] in User_Alias\n";
				 }
			      #print "group: $Aname member: $NewName\n";
			      if ($UserGroup{$NewName})
				 {$UserGroup{$NewName}.=",$Line[$ix]";}
			      else
				 {$UserGroup{$NewName}.="$Line[$ix]";}
			      }
			   }
        		elsif ( $Line[$ix] ne "" ) {
          			add_name($Line[$ix]);
          			}  # if Line
        		$ix++;
        		}  # end while ix

      		last TOKEN;
      		}  # end if User_Alias

    	  # this line must be in "user access_group" format
    	  # e.g. root ALL = (ALL) ALL
    	  add_name($Line[$ix]);
    	  last TOKEN;
    	  }  # end TOKEN: while ix


       $InputLine= "";
       } # end while

        close SUDOERS_FILE;
} # end sub parse


### Subroutine add_name - add name to list
#
# Call:
#   add_name(name)
#
# Arguments:
#   name - name to add to username alias list
#          ( %name if group name )
#
# User_Alias names are ignored.
# Group names are expanded to include all of the group members.
sub add_name {
  my $Aname = $_[0];
  if ( exists($AliasList{ $Aname }) ) {
    # ignore User_Alias names
    if($DEBUG){
      print "SUDOERS: Found user alias $Aname\n";
      }

    return 0;
    }
  if ( exists($ExemptList{ $Aname }) ) {
    # report (but do not track) system ids
    printf STDOUT "INFO:  exempt account %s\n", $Aname;
    return 0;
    }
  #
  # process user ids and group names
  if ( $Aname =~ /^%/ ) {
    # trim leading "%" to get group name
    $Aname =~ s/^%//;
    # get list of user ids
    if ($ggid{$Aname} eq "") {
      printf STDOUT "ERROR: invalid group %s in $SUDOERS\n", $Aname;
      $ErrCnt++;
      return 1;
      }
    my $Members;
    my $NewName;
    if($DEBUG){
      print "SUDOERS: Found group $Aname\n";
      }
    # Swapped out function calls with access of the prepopulated associative arrays
    $Members = $gmembers{$ggid{$Aname}};
    #print "Members: $Members\n";
    foreach $NewName (split ',', $Members) {
      # add each user id
      # NO check to see if ID is in EXEMPT list of users?!
      ## only add to hash if user is added alone, not as part of group
      ##########  $UserList{ $NewName }++;
      #print "group: $Aname member: $NewName\n";
      if ($UserGroup{$NewName})
        {$UserGroup{$NewName}.=",$Aname";}
      else
        {$UserGroup{$NewName}.="$Aname";}
      }
    }
  else {
    # add a simple user id
    $UserList{ $Aname }++;
    if($DEBUG){
      print "SUDOERS: Found user $Aname\n";
      }
    }  # end if/else group name
return 0;
}  # end subroutine add_name



sub openout()
{
	
	# Split out the path and filename portions
	my($filename, $directories, $suffix) = fileparse($OUTFILE);

	# path must exist
	if ( ! -e $directories )
	{
		die "ERROR: Output directory $directories does not exist\n";
	}

	# Resolve OUTFILE dirname to deferrence any symlinks
	# need to be absolutely sure what we are writing to !
	my $abs_path = abs_path($directories);
	#print "DEBUG: abs_path is $abs_path\n";	#debug

	# refuse to proceed if it looks like a system path 
	# eg /usr /etc /proc /opt
	if ( $abs_path =~ /^\/usr/ or $abs_path =~ /^\/etc/ or $abs_path =~ /^\/proc/ or $abs_path =~ /^\/opt/)
	{
		die "ERROR: Output directory $abs_path not allowed\n";
	}

	# refuse to proceed output file exists and is not a plain file
	if ( -e $OUTFILE and ! -f $OUTFILE )
	{
		die "ERROR: Won't remove $OUTFILE not a normal file\n";
	}
	
	# and refuse if it is a symlink
	if ( -l $OUTFILE )
	{
		die "ERROR: Won't remove $OUTFILE is a symlink\n";
	}

	# If it exists and is a standard file remove it
	if ( -e $OUTFILE and -f $OUTFILE )
	{
		`rm -f $OUTFILE` ;
		if ($? != 0) 
		{
			die "ERROR: Can't remove old $OUTFILE : $?\n";
		}
	}

	# Open the output file for writing
	open(OUTPUT_FILE, "> $OUTFILE") || die "ERROR: Can't open $OUTFILE for writing : $!\n";

} # end sub openout

sub report()
{
	#==============================================================================
	# Produce the urt extract file
	#==============================================================================
	# URT .scm format is ....
	# hostname<tab>os<tab>account<tab>userIDconv<tab>state<tab>l_logon<tab>group<tab>privilege 
	#
	#print "INFO:  Writing report for customer: $URTCUST to file: $OUTFILE\n";
	
	while ( (my $username, my $usergid) = each %user_gid)
	{
		## skip id if  it preceded by +: 
		if($username =~ /^\+/)
		  {
		  print "INFO:  User $username is excluded from output file\n";
		  next;
		  }

		# gather the info
		$usergecos = $user_gecos{$username};
		$usergroup = $group{$usergid};
	        $LCgecos=lc($usergecos); 

               #print "usergecos $usergecos\n";
               if($usergecos =~ /IBM\s+\S{6,6}\s+\S{3,3}/)
                 {
   	         $userstatus="I";
   	         $usercust="";
   	         $usercomment=$usergecos;
                 ($userserial, $userCCC)= $usergecos=~/IBM\s+(\S{6,6})\s+(\S{3,3})/;
		 $userCC=$userCCC; 
                 }
	       elsif ($usergecos =~ /\s*[^\/\s]*\/[^\/\s]*\/[^\/\s]*\/[^\/\s]*\/[^\/]*/ )
                 {
                 ($userCCC,$userstatus,$userserial,$usercust,$usercomment)=$usergecos=~/\s*([^\/\s]*)\/([^\/\s]*)\/([^\/\s]*)\/([^\/\s]*)\/([^\/]*)/;
		 $userCC=$userCCC;
                 }
               elsif ($LCgecos =~/s\=\S{9,9}/)
		 { if($debug){print " ##s=NNNNNN found\n"};
   	         $userstatus="I";
   	         $usercust="";
   	         $usercomment=$usergecos;
                 ($userserial,$userCCC)=$LCgecos=~/s\=(\S{6,6})(\S{3,3})/;
		 $userCC=$userCCC; 
                 }
               else
                 {
   	         $userstatus="C";
   	         $usercust="";
   	         $usercomment=$usergecos;
                 $userCC="897"; 
                 $userserial=""; 
 		 }
		
               #print "userserial $userserial\n";
               #print "userCC $userCC\n";
		# set userstate depending on what we were able to extract
		if ( $state_available == 1 )
		{
			# we have extracted all disabled accounts - rest must be enabled
			#if $user_state{username}=have value  the user_state=value
			#else user_state="Enabled" 
			$userstate = $user_state{$username} ? $user_state{$username} : "Enabled";
			$scm_userstate = $scm_user_state{$username} ne "" ? $scm_user_state{$username} : "0";
		}
		else
		{
			# we may have extracted some disabled accounts eg from passwd file but maybe not all
			# so default set blank 
			$userstate = $user_state{$username} ? $user_state{$username} : "";
			$scm_userstate = $scm_user_state{$username} ne "" ? $scm_user_state{$username} : "0";
		}

		$userllogon = "";	# lastlog files are very OS and version dependent so just empty
		$groupField="";
		$privField="";

		if($user_privuser{$username})
		  {
		  $privField=$username;
		  }

		if($DEBUG){
		  print "DEBUG: $username found primary group $usergroup\n"; #debug
		}
		if($DEBUG){
		  print "DEBUG: user_privgroups{$username}:  $user_privgroups{$username}\n"; #debug
		  print "DEBUG: user_allgroups{$username}:  $user_allgroups{$username}\n"; #debug
		}
       
		# Add primary group to list of priv groups if neccessary
		if ($usergroup =~ /$PRIVGROUPS/)
		  {
		  if (exists $user_privgroups{$username})
		    {
		    $userprivgroups = $user_privgroups{$username} . "," . $usergroup;
		    } # end if
	          else
		    {
		    $userprivgroups = $usergroup;
		    } # end if
		  }
	        else
		  {
		  $userprivgroups = $user_privgroups{$username}
		  } # end if

	        if (exists $user_allgroups{$username})
		    {
		    $userallgroups = $user_allgroups{$username} . "," . $usergroup;
		    } # end if
	        else
		    {
		    $userallgroups = $usergroup;
		    } # end if

		if($DEBUG){
		  print "DEBUG: added primary user_privgroups{$username}:  $user_privgroups{$username}\n"; #debug
		  print "DEBUG: added primary userprivgroups: $userprivgroups\n"; #debug
		  print "DEBUG: added primary user_allgroups{$username}:  $user_allgroups{$username}\n"; #debug
		  print "DEBUG: added primary userallgroups: $userallgroups\n"; #debug
		}
                #uniquify the privgrouplist
		if($userprivgroups ne "")
		  {
		  %hash="";
	          @cases = split(/,/,$userprivgroups);
                  $userprivgroups = "";
                  %hash = map { $_ => 1 } @cases;
		  $userprivgroups = join(",", sort keys %hash);
		  $groupValue="GRP($userprivgroups)";
		  if($privField eq "")
		    {$privField=$groupValue;}
		  else
		    {$privField=$privField.",".$groupValue;}
		  }

                #uniquify the allgrouplist
		# seting group field with all groups
		if($userallgroups ne "")
		  {
		  %hash="";
	          @cases = split(/,/,$userallgroups);
                  $userallgroups = "";
                  %hash = map { $_ => 1 } @cases;
		  $userallgroups = join(",", sort keys %hash);
		  $groupField="$userallgroups";
		  }

   		$SudoValue="";
  		if ($UserList{$username})
		  {$SudoValue="SUDO\_$username";
   		  delete $UserList{$username};
   		  if($privField eq "")
		    {$privField=$SudoValue;}
		  else
		    {$privField=$privField.",".$SudoValue;}
		  }

  		if ($UserGroup{$username})
		  {
		  $usersudogroups=$UserGroup{$username};
                  #uniquify the sudogrouplist
		  %hash="";
	          @cases = split(/,/,$usersudogroups);
                  $usersudogroups = "";
                  %hash = map { $_ => 1 } @cases;
		  $usersudogroups = join(",", sort keys %hash);

		  $SudoGroup="SUDO_GRP($usersudogroups)";
   		  if($privField eq "")
		    {$privField=$SudoGroup;}
		  else
		    {$privField=$privField.",".$SudoGroup;}
   		  }

  		if ($SUDOALL)
		  {
   		  if($privField eq "")
		    {$privField="SUDO_ALL";}
		  else
		    {$privField=$privField.",SUDO_ALL";}
   		  }


                # V5.2.6  2007-12-11   # leduc  If comments contain IBM flag = I
               if (($userstatus =~ m/C/g) and ($usercomment =~ m/IBM/g)) {
                   #debug print "Converting\n$userstatus\nto\n";
                   $userstatus =~ s/C/I/g;
                   #debug print "$OWNERSHIP\n";
                }

		
		# Write the line
		if($SCMFORMAT)
	           #SCM9 hostname<tab>os<tab>auditdate<tab>account<tab>userIDconv<tab>state<tab>l_logon<tab>group<tab>privilege
		   {print OUTPUT_FILE "$HOST\t$OS\t$myAUDITDATE\t$username\t$userCC/$userstatus/$userserial/$usercust/$usercomment\t$scm_userstate\t$userllogon\t$groupField\t$privField\n";}
		elsif($MEF2FORMAT)
		  #MEF2 customer|system|account|userID convention data|group|state|l_logon|privilege
		  {print OUTPUT_FILE "$URTCUST|$HOST|$username|$userCC/$userstatus/$userserial/$usercust/$usercomment|$groupField|$userstate|$userllogon|$privField\n";}
	        else
		  #MEF3 “customer|identifier type|server identifier/application identifier|OS name/Application name|account|UICMode|userID convention data|state|l_logon |group|privilege”
		  #
		  {print OUTPUT_FILE "$URTCUST|S|$HOST|$OS|$username||$userCC/$userstatus/$userserial/$usercust/$usercomment|$userstate|$userllogon|$groupField|$privField\n";}

	} # end while


        ## Add dummy record to end of file
        if($SCMFORMAT)
  	   #SCM9 hostname<tab>os<tab>auditdate<tab>account<tab>userIDconv<tab>state<tab>l_logon<tab>group<tab>privilege
	   {print OUTPUT_FILE "$HOST\t$OS\t$myAUDITDATE\tNOTaRealID\t000/V///$myAUDITDATE:$0:VER=$VERSION:CKSUM=$CKSUM\t1\t\t\t\n";}
        elsif($MEF2FORMAT)
	   #MEF2 customer|system|account|userID convention data|group|state|l_logon|privilege
	   {print OUTPUT_FILE "$URTCUST|$HOST|NOTaRealID|000/V///$myAUDITDATE:$0:VER=$VERSION:CKSUM=$CKSUM||||\n";}
        else
	   #MEF3 “customer|identifier type|server identifier/application identifier|OS name/Application name|account|UICMode|userID convention data|state|l_logon |group|privilege”
	   {print OUTPUT_FILE "$URTCUST|S|$HOST|$OS|NOTaRealID||000/V///$myAUDITDATE:$0:VER=$VERSION:CKSUM=$CKSUM||||\n";}



	
    	while (($key,$value) = each %UserList) {
   	  $SudoValue="";
  	  printf "ERROR: invalid user name %s in $SUDOERS\n", $key;
  	  $ErrCnt++;
  	  }

	printf "\n  %d errors encountered\n", $ErrCnt;
   
	close OUTPUT_FILE || die "ERROR: Problem closing output file : $!\n";
	print "\nINFO:  Report completed successfully\n"

	
} # end sub report
