use inc::Module::Install;
name 'Algorithm-Clustering-BiSection';
all_from 'lib/Algorithm/Clustering/BiSection.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
