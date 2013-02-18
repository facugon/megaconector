#!/usr/bin/perl
# -------------------------------------------------------------

###############################################################
package Object;
###############################################################
use strict;

sub new {
    my ($self) = {};
    bless $self,'Object';
    return $self;
}
### DESTROY
sub DESTROY {
    my ($self) = shift;
    return undef $self;
}

#### A GENERAL GETTER
sub get {
# receive the attribute name by parameter
        my ($self) = shift;
        my ($attribute) = @_[0];
        return $self->{$attribute};
}
#### A GENERAL SETTER
sub set {
        my ($self) = shift;
        my ($attribute,$newValue) = @_;
        $self->{$attribute} = $newValue;
}

sub print {
        my ($self) = shift;
        my ($k,$v);
        print "********************************\n";
        print "* Printing object [ $self ]\n";
        while ( ($k,$v) = each %$self ) {
                print "* $k => $v\n";
        }
        print "*******************************\n";
}

"1;"

__END__
