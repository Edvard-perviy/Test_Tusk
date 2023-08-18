package MyWeb::Data;
use DBI;

use constant LIMIT => 100;

# данные для подключение к базе mysql
	my $db = 'LOGS';
	my $user = 'eduard';
	my $password = '';

my $dbh = DBI->connect("DBI:mysql:$db", $user, $password) or return "Error DBI connect: $!";

sub new {
	my ($self) = @_;
	my $class = bless {}, $self;
	return $class;
}

sub get_logs {
	my ($class, $input) = @_;

    my $messages = $dbh->selectall_arrayref("
        SELECT
            int_id,
            unix_timestamp(m.created) ut,
            m.created created,
            m.str str
        FROM
            message m
	    JOIN
            log USING (int_id)
        WHERE
            address = ?
        ORDER BY
            int_id DESC,
            m.created DESC
        LIMIT ?
        ", { Slice => {} }, $input, LIMIT
    );
    my $logs = $dbh->selectall_arrayref("
        SELECT
            int_id,
            unix_timestamp(created) ut,
            created,
            str
        FROM
            log
        WHERE
            address = ?
        ORDER BY
            int_id DESC,
            created DESC
        LIMIT ?
        ", { Slice => {} }, $input, LIMIT
    );

    my $hash_logs = {};
    for (@$logs, @$messages) {
        push $hash_logs->{ $_->{int_id} }->@* => $_;
    }
    for (values %$hash_logs) {
        # сортировка по дате внутри каждого int_id
        $_ = [ sort {$b->{ut} <=> $a->{ut}} @$_ ];
    }
    # внешняя сортировка по int_id
    [ map {$hash_logs->{$_}->@*} sort {$b cmp $a} keys %$hash_logs ];
}
