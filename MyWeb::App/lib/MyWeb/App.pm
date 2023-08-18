package MyWeb::App;
use Dancer2;
use DBI;

use MyWeb::Data;

our $VERSION = '0.1';

get '/' => sub {
    template 'index' => { 'title' => 'Поиск логов', 'limit' => MyWeb::Data->LIMIT };
};

post '/table' => sub {
    my $input = param('address');

    unless ($input) {
        return template 'error' => { 'title' => 'Поиск логов', 'text' => "Введите адрес!" };
    }

    # получаем отсортированные логи из двух таблиц 
    my $sort_logs = MyWeb::Data->get_logs($input);

    my $warning = '';
    if (@$sort_logs > MyWeb::Data->LIMIT) {
        @$sort_logs = @$sort_logs[0 .. MyWeb::Data->LIMIT-1];
        $warning = 'Кол-во записей превышает ' . MyWeb::Data->LIMIT . '!';
    }

    my $num = 0;
    my @out;
    for (@$sort_logs) {
        $num ++;
        push @out => qq[<tr><td>$num</td><td>$_->{created}</td><td>$_->{str}</td></tr>];
    }

    unless (@out) {
        return template 'error' => { 'title' => 'Поиск логов', 'text' => "Логи по адресу '$input' не найдены!" };
    }

    return template 'table' => { 'title' => 'Поиск логов', 'list' => \@out, 'warning' => $warning };
};

true;
