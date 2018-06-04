function deb_train = debounce(train,min_interval)

dd = diff(train);
deb_train = train([true dd>min_interval]);
end