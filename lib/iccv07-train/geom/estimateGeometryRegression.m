function params = estimateGeometryRegression(bndinfo, X, gdatadir)

g2g = [0 1 2 2 2 3 4 5];

npg = 3;
gconf = cell(numel(bndinfo), npg);

dataperim = 10000;

if 1
for f = 1:numel(bndinfo)
   
    %disp(num2str(f))
    
    bn = strtok(bndinfo(f).imname, '.');
    
    gdata = load([gdatadir bn '_gdata.mat']);
    imsegs = gdata.imsegs;
    
    gtlab{f} = g2g(imsegs.labels(imsegs.segimage)+1);        
    
    randind = randperm(numel(gtlab{f}));
    randind = randind(1:dataperim);
    gtlab{f} = gtlab{f}(randind);
    ind = gtlab{f}==0;
    gtlab{f}(ind) = [];
    randind(ind) = [];
    
    pg{1} = X(f).region.pg1;
    pg{2} = X(f).region.pg2;
    if isfield(X(f).region, 'pg3')
        pg{3} = X(f).region.pg3;
    end
        
    for k = 1:numel(pg)
        pg{k} = [pg{k}(:, 1) sum(pg{k}(:, 2:4), 2) pg{k}(:, 5:7)];
        pg{k} = (pg{k}+1E-4) ./ repmat(sum(pg{k}+1E-4, 2), [1 size(pg{k}, 2)]);
        
        gconf{f,k} = zeros(numel(randind), 5);
        for g = 1:5
            tmpim = pg{k}(bndinfo(f).wseg, g);
            gconf{f,k}(:, g) = log(tmpim(randind));
        end
    end      
end
save './tmp/tmpdata.mat' gtlab gconf
else
    load './tmp/tmpdata.mat'
end

options = optimset('Display', 'iter');
gconf = gconf(:, 1:numel(pg));
params=  zeros(1, numel(pg));
params(1) = 1;

%params = fminunc(@(p) getNegLL(p, gtlab, gconf), params, options);
params = fmincon(@(p) getNegLL(p, gtlab, gconf), params, [], [], [], [], ...
    zeros(size(params)), 5*ones(size(params)), [], options);


%% likelihood
function totalLL = getNegLL(params, gtlab, gconf)

nx = 0;
totalp = 0;
totalLL = 0;
for f = 1:numel(gtlab)
    dataLL = zeros(size(gconf{f,1}));
    for k = 1:size(gconf, 2)
        dataLL = dataLL + params(k)*gconf{f,k};
    end
    pdata = exp(dataLL);
    pdata = pdata ./ repmat(sum(pdata, 2), [1 size(pdata, 2)]);
    
    correctind = (1:numel(gtlab{f})) + (gtlab{f}-1).*numel(gtlab{f});
    
    totalLL = totalLL + sum(log(pdata(correctind)));    
    totalp = totalp + sum(pdata(correctind));
    nx = nx + numel(correctind);
end
totalLL = -totalLL;
%totalLL = 1 - totalp/nx;
disp(['Mean p = ' num2str(totalp/nx) '  ' num2str(params)])

    