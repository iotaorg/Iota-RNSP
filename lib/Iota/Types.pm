package Iota::Types;

use MooseX::Types -declare => [
    qw( VariableType DataStr VisibilityLevel
      )
];
use MooseX::Types::Moose qw(ArrayRef HashRef CodeRef Str ScalarRef);
use Moose::Util::TypeConstraints;

#use DateTime::Duration;
#use DateTime::Format::Duration;
#use DateTimeX::Easy;

use DateTime::Duration;
use DateTime::Format::Duration;
use DateTimeX::Easy;

enum 'VariableTypeEnum', [qw(int str num)];

subtype VariableType, as 'VariableTypeEnum';

enum 'VisibilityLevelEnum', [qw(public private restrict country)];

subtype VisibilityLevel, as 'VisibilityLevelEnum';

subtype DataStr, as Str, where {
    eval { DateTimeX::Easy->new($_)->datetime };
    return $@ eq '';
}, message { "$_ data invalida" };

coerce DataStr, from Str, via {
    DateTimeX::Easy->new($_)->datetime;
};

=pod

subtype Duration, as Str;

coerce Duration, from ArrayRef, via {
    DateTime::Format::Duration->new( pattern => '%e days, %k hours' )
      ->format_duration( DateTime::Duration->new( days => $_->[0], hours => $_->[1] ) );
};
=cut

1;
