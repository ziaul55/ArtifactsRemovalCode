%class 1
x = [0 1 3];
y = [4 3 4];

meanx=mean(x);
variancex=var(x);

meany=mean(y);
variancey=var(y);

% class 2
x = [4 3 4];
y = [1 1 3];

meanx = mean(x);
meany = mean(y);
variancey=var(y);
variancex=var(x);

%%
point = [3 3];

%probablity class 1
p1y = 1/(variancey*sqrt(3.14));
liczniky = -(point(2)-meany)^2;
mianowniky = 2*variancey;
expony = exp(liczniky/mianowniky);
p1y=p1y*expony;



p1x = 1/(variancex*sqrt(3.14));
licznikx = -(point(2)-meanx)^2;
mianownikx = 2*variancex;
exponx = exp(licznikx/mianownikx);
p1x=p1x*exponx;