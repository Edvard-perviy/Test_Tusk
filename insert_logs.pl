#!/usr/bin/env perl

use v5.14;
use warnings;

=comment

Запись логов в БД

=cut

use DBI;

# данные для подключение к базе mysql
my $db = 'LOGS';
my $user = 'eduard';
my $password = 'lefhlHELPBR';
# путь к директории, где лежат файлы с логами
my $my_dir_tmp = './tmp_logs/';

my $dbh = DBI->connect("DBI:mysql:$db", $user, $password) or die "Error DBI connect: $!";
my $sth_m = $dbh->prepare("INSERT INTO message (created, id, int_id, str) VALUES (?, ?, ?, ?)");
my $sth_l = $dbh->prepare("INSERT INTO log (created, int_id, address, str) VALUES (?, ?, ?, ?)");

opendir(my $fh_dir, $my_dir_tmp) or die("Cannot opendir $my_dir_tmp: $!");
my @dir = readdir($fh_dir);
closedir($fh_dir);

for my $file (@dir) {
    my $file_path = $my_dir_tmp . $file;

    next unless -f($file_path) && -r($file_path);

    open(my $fh, '<', $file_path) or die "Cannot open $file_path: $!";

    my $log_id = 0;
    while (<$fh>) {
        chomp($_);
        $log_id++;

        next unless $_ =~ /^(\S+\s\S+)\s(\S{1,16})\s(.*)$/;

        my ($date, $int_id, $info) = ($1, $2, $3);

        if ($info =~ /^<=\s(.*)$/) {
            # уходят в message
            $sth_m->execute($date, $log_id, $int_id, $1);
        } elsif ($info =~ /^[<>=\-\*]+\s(.*?@\S+)\s(.*)$/) {
            # уходит в log с адресом получателя
            $sth_l->execute($date, $int_id, $1, $2);
        } else {
            $info =~ s/^[<>=\-\*]+//;
            # уходит в log без адреса
            $sth_l->execute($date, $int_id, '', $info);
        }
    }
    close $fh;
}
